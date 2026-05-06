//
//  SubscriptionRecord.swift
//  Budgetella
//
//  StoreKit 2 Transaction.currentEntitlements'tan sync'lenen lokal mirror.
//  userId unique olduğu için per-user tek kayıt.
//  Kaynak-of-truth: Apple App Store (StoreKit 2 verified transactions).
//

import Foundation
import SwiftData

public enum SubscriptionStatus: String, Codable, Sendable {
    case active
    case expired
    case gracePeriod  = "grace_period"
    case paused
    case none
}

@Model
public final class SubscriptionRecord {

    @Attribute(.unique) public var userId: String

    public var isPremium: Bool
    /// RevenueCat entitlement identifier.
    public var entitlement: String
    /// App Store product ID. Örn: "budgetella.premium.monthly"
    public var productId: String?
    public var expiresAt: Date?
    public var statusRaw: String
    /// App Store original transaction ID veya nil.
    public var customerId: String?
    public var lastSyncedAt: Date

    public init(
        userId: String,
        isPremium: Bool = false,
        entitlement: String = "premium",
        productId: String? = nil,
        expiresAt: Date? = nil,
        status: SubscriptionStatus = .none,
        customerId: String? = nil
    ) {
        self.userId = userId
        self.isPremium = isPremium
        self.entitlement = entitlement
        self.productId = productId
        self.expiresAt = expiresAt
        self.statusRaw = status.rawValue
        self.customerId = customerId
        self.lastSyncedAt = .now
    }
}

public extension SubscriptionRecord {
    var status: SubscriptionStatus {
        SubscriptionStatus(rawValue: statusRaw) ?? .none
    }

    var isMonthly: Bool {
        productId?.contains("monthly") == true
    }

    var isYearly: Bool {
        productId?.contains("annually") == true
    }

    /// Abonelik süresi dolmuş mu? Grace period dahil premium sayılır.
    var isActiveOrGrace: Bool {
        status == .active || status == .gracePeriod
    }
}
