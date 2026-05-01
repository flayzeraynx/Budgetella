//
//  SubscriptionRecord.swift
//  Budgetella
//
//  RevenueCat'ten sync'lenen abonelik durumunun lokal SwiftData mirror'ı.
//  userId unique olduğu için per-user tek kayıt.
//  Kaynak-of-truth: RevenueCat CustomerInfo. Bu kayıt offline read içindir.
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
    /// RevenueCat customer ID ($RCAnonymousID veya Firebase UID).
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
        productId?.contains("yearly") == true
    }

    /// Abonelik süresi dolmuş mu? Grace period dahil premium sayılır.
    var isActiveOrGrace: Bool {
        status == .active || status == .gracePeriod
    }
}
