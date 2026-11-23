//
//  SubscriptionService.swift
//  Budgetella
//
//  Native StoreKit 2 wrapper — RevenueCat yok.
//
//  Product ID'ler:
//    com.ozankilic.budgetella.premium.monthly  — aylık $4.99 + 7 gün trial
//    com.ozankilic.budgetella.premium.annually  — yıllık $39.99 + 7 gün trial
//    com.ozankilic.budgetella.premium.lifetime — tek seferlik $99.99 (non-consumable)
//

import Foundation
import StoreKit
import SwiftData

@MainActor
@Observable
public final class SubscriptionService {

    // MARK: - State

    public var isSubscriptionActive = false
    public var isLifetimePurchased  = false
    public var activePlanProductId: String?
    public var isLoading = false
    public var errorMessage: String?

    /// Until the first StoreKit refresh lands, trust the last persisted state so
    /// paying users never see a locked feature flash at launch.
    public var isPremium: Bool {
        isSubscriptionActive || isLifetimePurchased || (!hasRefreshed && cachedPremium)
    }

    /// Product IDs whose free-trial intro offer this Apple ID can still redeem.
    public private(set) var trialEligibleProductIDs: Set<String> = []

    private var hasRefreshed = false
    private let cachedPremium = UserDefaults.standard.bool(forKey: "budgetella.isPremium")

    /// Single app-wide instance — one `Transaction.updates` listener.
    public static let shared = SubscriptionService()

    public var monthlyProduct:  Product?
    public var yearlyProduct:   Product?
    public var lifetimeProduct: Product?

    /// App Store abonelik yönetimi deep link (Apple 5.1.1(v) zorunlu).
    public let managementURL = URL(string: "itms-apps://apps.apple.com/account/subscriptions")!

    nonisolated(unsafe) private var transactionListener: Task<Void, Never>?

    // MARK: - Dev override

    #if DEBUG
    private static let devPremiumUIDs: Set<String> = [
        "7n48wY1HdMWD8ZdX00hzqwZAcsb2" // Ozzy — debug only, stripped from Release
    ]
    #else
    private static let devPremiumUIDs: Set<String> = []
    #endif

    // MARK: - Product IDs

    public enum ProductID {
        static let monthly  = "com.ozankilic.budgetella.premium.monthly"
        static let yearly   = "com.ozankilic.budgetella.premium.annually"
        static let lifetime = "com.ozankilic.budgetella.premium.lifetime"
        static var all: [String] { [monthly, yearly, lifetime] }
    }

    // MARK: - Init

    private init() {
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Setup

    public func setup(userId: String = "") async {
        await fetchProducts()
        await refreshStatus(userId: userId)
    }

    // MARK: - Products

    private func fetchProducts() async {
        do {
            let products = try await Product.products(for: ProductID.all)
            for product in products {
                switch product.id {
                case ProductID.monthly:  monthlyProduct  = product
                case ProductID.yearly:   yearlyProduct   = product
                case ProductID.lifetime: lifetimeProduct = product
                default: break
                }
            }
            await refreshTrialEligibility()
        } catch {
            errorMessage = String(format: String(localized: "Ürünler yüklenemedi: %@"), error.localizedDescription)
        }
    }

    /// Trial wording may only be shown when the product has a free-trial intro
    /// offer AND this Apple ID has not used one in the subscription group.
    private func refreshTrialEligibility() async {
        var eligible: Set<String> = []
        for product in [monthlyProduct, yearlyProduct].compactMap({ $0 }) {
            guard let sub = product.subscription,
                  sub.introductoryOffer?.paymentMode == .freeTrial,
                  await sub.isEligibleForIntroOffer else { continue }
            eligible.insert(product.id)
        }
        trialEligibleProductIDs = eligible
    }

    // MARK: - Status

    public func refreshStatus(userId: String = "") async {
        defer { hasRefreshed = true }
        // Shared instance: callers without a uid (purchase, restore, listener)
        // must not drop the DEBUG dev override another screen established.
        let userId = userId.isEmpty
            ? (UserDefaults.standard.string(forKey: "currentUserId") ?? "")
            : userId
        if !userId.isEmpty && Self.devPremiumUIDs.contains(userId) {
            isSubscriptionActive = true
            isLifetimePurchased  = false
            activePlanProductId  = ProductID.yearly
            Self.persistPremiumState(true)
            return
        }
        var hasSubscription = false
        var hasLifetime     = false
        var planId: String?
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            switch tx.productID {
            case ProductID.monthly, ProductID.yearly:
                if tx.productType == .autoRenewable {
                    hasSubscription = true
                    planId = tx.productID
                }
            case ProductID.lifetime:
                if tx.productType == .nonConsumable {
                    hasLifetime = true
                    planId = tx.productID
                }
            default:
                break
            }
        }
        isSubscriptionActive = hasSubscription
        isLifetimePurchased  = hasLifetime
        activePlanProductId  = planId
        Self.persistPremiumState(isSubscriptionActive || isLifetimePurchased)
    }

    /// UserDefaults'a yazar — widget ve QuickEntry buradan okur.
    private static func persistPremiumState(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "budgetella.isPremium")
    }

    /// SwiftData'ya lokal mirror yazar.
    public func syncToLocalDB(modelContext: ModelContext, userId: String) async {
        var activeProductId: String?
        var expiresAt: Date?

        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let tx) = result,
                  ProductID.all.contains(tx.productID) else { continue }
            activeProductId = tx.productID
            expiresAt = tx.expirationDate  // lifetime için nil, doğru
        }

        let record = SubscriptionRecord(
            userId: userId,
            isPremium: isPremium,
            entitlement: "premium",
            productId: activeProductId,
            expiresAt: expiresAt,
            status: isPremium ? .active : .none
        )

        let existing = try? modelContext.fetch(
            FetchDescriptor<SubscriptionRecord>(
                predicate: #Predicate { $0.userId == userId }
            )
        )
        existing?.forEach { modelContext.delete($0) }
        modelContext.insert(record)
        try? modelContext.save()
    }

    // MARK: - Purchase

    public func purchase(_ product: Product) async throws {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let tx) = verification {
                await tx.finish()
                await refreshStatus()
                await refreshTrialEligibility()
            } else {
                throw SubscriptionError.verificationFailed
            }
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Restore (Apple 5.1.1(v) zorunlu)

    public func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        try await AppStore.sync()
        await refreshStatus()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await result in StoreKit.Transaction.updates {
                if case .verified(let tx) = result {
                    await tx.finish()
                    await self?.refreshStatus()
                }
            }
        }
    }
}

// MARK: - Error

public enum SubscriptionError: LocalizedError {
    case verificationFailed

    public var errorDescription: String? {
        String(localized: "Satın alma doğrulanamadı. Lütfen tekrar deneyin.")
    }
}
