//
//  SubscriptionService.swift
//  Budgetella
//
//  RevenueCat wrapper. Webapp SubscriptionContext.tsx → Swift port.
//  @MainActor @Observable — SwiftUI'dan direkt bind edilir.
//
//  Entitlement ID: "premium"
//  Offering ID: "default" (monthly + yearly packages)
//  App Store deep link: itms-apps://apps.apple.com/account/subscriptions
//

import Foundation
import SwiftData
@preconcurrency import RevenueCat

@MainActor
@Observable
public final class SubscriptionService {

    // MARK: - State

    public var isPremium = false
    public var isLoading = false
    public var errorMessage: String?
    public var currentOffering: Offering?

    /// App Store abonelik yönetimi deep link (Apple 5.1.1(v) zorunlu).
    public let managementURL = URL(string: "itms-apps://apps.apple.com/account/subscriptions")!

    // MARK: - Configure

    /// Firebase Auth sign-in sonrası çağrılır — RevenueCat kullanıcıyı tanır.
    public func configure(userId: String) async {
        do {
            let info = try await Purchases.shared.logIn(userId).customerInfo
            apply(customerInfo: info)
        } catch {
            // Login hatası non-fatal; anonymous state'te devam et
        }
        await fetchOffering()
    }

    // MARK: - Status Fetch

    public func refreshStatus() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let info = try await Purchases.shared.customerInfo()
            apply(customerInfo: info)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// SwiftData'ya lokal mirror yazar.
    public func syncToLocalDB(modelContext: ModelContext, userId: String) async {
        do {
            let info = try await Purchases.shared.customerInfo()
            apply(customerInfo: info)
            let entitlement = info.entitlements["premium"]
            let record = SubscriptionRecord(
                userId: userId,
                isPremium: isPremium,
                entitlement: "premium",
                productId: entitlement?.productIdentifier,
                expiresAt: entitlement?.expirationDate,
                status: isPremium ? .active : .none,
                customerId: info.originalAppUserId
            )
            // Upsert: aynı userId varsa sil, yenisini ekle
            let existing = try? modelContext.fetch(
                FetchDescriptor<SubscriptionRecord>(
                    predicate: #Predicate { $0.userId == userId }
                )
            )
            existing?.forEach { modelContext.delete($0) }
            modelContext.insert(record)
        } catch {
            // Offline veya RevenueCat unreachable — mevcut lokal kayıt korunur
        }
    }

    // MARK: - Purchase

    public func purchase(package: Package) async throws {
        isLoading = true
        defer { isLoading = false }
        let result = try await Purchases.shared.purchase(package: package)
        apply(customerInfo: result.customerInfo)
    }

    // MARK: - Restore (Apple 5.1.1(v) zorunlu)

    public func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        let info = try await Purchases.shared.restorePurchases()
        apply(customerInfo: info)
    }

    // MARK: - Sign Out

    public func logOut() async {
        _ = try? await Purchases.shared.logOut()
        isPremium = false
    }

    // MARK: - Private

    private func fetchOffering() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
        } catch {
            // Offering fetch hatası non-fatal — paywall boş görünür
        }
    }

    private func apply(customerInfo: CustomerInfo) {
        isPremium = customerInfo.entitlements["premium"]?.isActive == true
    }
}
