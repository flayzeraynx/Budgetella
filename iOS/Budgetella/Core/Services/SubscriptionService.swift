//
//  SubscriptionService.swift
//  Budgetella
//
//  Native StoreKit 2 wrapper — RevenueCat yok.
//
//  Product ID'ler:
//    com.ozankilic.budgetella.premium.monthly  — aylık $4.99 + 7 gün trial
//    com.ozankilic.budgetella.premium.yearly   — yıllık $39.99 + 7 gün trial
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

    public var isPremium: Bool { isSubscriptionActive || isLifetimePurchased }

    public var monthlyProduct:  Product?
    public var yearlyProduct:   Product?
    public var lifetimeProduct: Product?

    /// App Store abonelik yönetimi deep link (Apple 5.1.1(v) zorunlu).
    public let managementURL = URL(string: "itms-apps://apps.apple.com/account/subscriptions")!

    private var transactionListener: Task<Void, Never>?

    // MARK: - Dev override

    private static let devPremiumUIDs: Set<String> = [
        "7n48wY1HdMWD8ZdX00hzqwZAcsb2" // Ozzy
    ]

    // MARK: - Product IDs

    public enum ProductID {
        static let monthly  = "com.ozankilic.budgetella.premium.monthly"
        static let yearly   = "com.ozankilic.budgetella.premium.yearly"
        static let lifetime = "com.ozankilic.budgetella.premium.lifetime"
        static var all: [String] { [monthly, yearly, lifetime] }
    }

    // MARK: - Init

    public init() {
        transactionListener = listenForTransactions()
    }

    deinit {
        MainActor.assumeIsolated { transactionListener?.cancel() }
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
        } catch {
            errorMessage = "Ürünler yüklenemedi: \(error.localizedDescription)"
        }
    }

    // MARK: - Status

    public func refreshStatus(userId: String = "") async {
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
        "Satın alma doğrulanamadı. Lütfen tekrar deneyin."
    }
}
