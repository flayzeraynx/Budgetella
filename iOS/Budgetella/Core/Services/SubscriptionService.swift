//
//  SubscriptionService.swift
//  Budgetella
//
//  Native StoreKit 2 wrapper — RevenueCat yok.
//  Reelight'taki pattern'le aynı yaklaşım: StoreKit.Transaction.currentEntitlements
//  ile Apple tarafında verify edilen receipt.
//
//  NOT: SwiftData'da da `Transaction` modeli var — StoreKit tipine her yerde
//  `StoreKit.Transaction` olarak explicit erişiyoruz.
//
//  Product ID'ler:
//    budgetella.premium.monthly  — aylık ₺49,90 + 7 gün trial
//    budgetella.premium.yearly   — yıllık ₺399 + 7 gün trial
//

import Foundation
import StoreKit
import SwiftData

@MainActor
@Observable
public final class SubscriptionService {

    // MARK: - State

    public var isPremium = false
    public var isLoading = false
    public var errorMessage: String?

    public var monthlyProduct: Product?
    public var yearlyProduct: Product?

    /// App Store abonelik yönetimi deep link (Apple 5.1.1(v) zorunlu).
    public let managementURL = URL(string: "itms-apps://apps.apple.com/account/subscriptions")!

    // nonisolated(unsafe): deinit'te cancel çağrısı için
    nonisolated(unsafe) private var transactionListener: Task<Void, Never>?

    // MARK: - Product IDs

    public enum ProductID {
        static let monthly = "budgetella.premium.monthly"
        static let yearly  = "budgetella.premium.yearly"
        static var all: [String] { [monthly, yearly] }
    }

    // MARK: - Init

    public init() {
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Setup

    public func setup() async {
        await fetchProducts()
        await refreshStatus()
    }

    // MARK: - Products

    private func fetchProducts() async {
        do {
            let products = try await Product.products(for: ProductID.all)
            for product in products {
                if product.id == ProductID.monthly { monthlyProduct = product }
                if product.id == ProductID.yearly  { yearlyProduct  = product }
            }
        } catch {
            errorMessage = "Ürünler yüklenemedi: \(error.localizedDescription)"
        }
    }

    // MARK: - Status

    /// Apple'ın sunucusunda verify edilmiş aktif entitlement'ları kontrol eder.
    public func refreshStatus() async {
        var hasPremium = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productType == .autoRenewable,
               ProductID.all.contains(tx.productID) {
                hasPremium = true
            }
        }
        isPremium = hasPremium
    }

    /// SwiftData'ya lokal mirror yazar.
    public func syncToLocalDB(modelContext: ModelContext, userId: String) async {
        var activeProductId: String?
        var expiresAt: Date?

        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               ProductID.all.contains(tx.productID) {
                activeProductId = tx.productID
                expiresAt = tx.expirationDate
            }
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
        case .userCancelled:
            break
        case .pending:
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
