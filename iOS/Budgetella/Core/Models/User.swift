//
//  User.swift
//  Budgetella
//
//  SwiftData @Model — local user shadow. Source of truth Firebase Firestore'dur;
//  bu model sadece local cache + offline support için.
//
//  Premium status RevenueCat üzerinden Firestore'a webhook ile yazılır;
//  AuthService onAuthStateChanged listener'ı Firestore'dan bu local kaydı senkronize eder.
//

import Foundation
import SwiftData

public enum SubscriptionType: String, Codable, CaseIterable, Sendable {
    case none
    case monthly
    case yearly
    /// V1.0+ early adopter pump için saklı tutuluyor.
    case lifetime
}

@Model
public final class User {

    @Attribute(.unique) public var uid: String
    public var email: String
    public var displayName: String?
    public var photoURL: String?

    // Subscription state — RevenueCat + Firestore'dan sync'lenir
    public var isPremium: Bool
    public var subscriptionType: SubscriptionType
    public var subscriptionId: String?
    public var subscriptionEndDate: Date?
    public var subscriptionStatus: String?  // "active" | "canceled" | "past_due" | ...
    public var customerId: String?           // RevenueCat App User ID veya Stripe Customer ID

    /// Role-based admin kontrolü (eski hardcoded email check'in yerine).
    public var roles: [String]

    // ── Gamification (Profile screen — Ozzy V1 kararı 2026-05-01)
    /// Ardışık aktif gün sayısı. AchievementEngine her gün kontrol eder.
    public var dailyStreakCount: Int
    /// Mevcut streak başlangıç tarihi. `lastActiveDate` 1 günden fazla atlarsa sıfırlanır.
    public var streakStartedAt: Date?
    /// Son işlem giriş tarihi (sadece tarih kısmı, saat 00:00 normalize).
    public var lastActiveDate: Date?

    public var lastSyncedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        uid: String,
        email: String,
        displayName: String? = nil,
        photoURL: String? = nil,
        isPremium: Bool = false,
        subscriptionType: SubscriptionType = .none,
        subscriptionId: String? = nil,
        subscriptionEndDate: Date? = nil,
        subscriptionStatus: String? = nil,
        customerId: String? = nil,
        roles: [String] = [],
        dailyStreakCount: Int = 0,
        streakStartedAt: Date? = nil,
        lastActiveDate: Date? = nil
    ) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.isPremium = isPremium
        self.subscriptionType = subscriptionType
        self.subscriptionId = subscriptionId
        self.subscriptionEndDate = subscriptionEndDate
        self.subscriptionStatus = subscriptionStatus
        self.customerId = customerId
        self.roles = roles
        self.dailyStreakCount = dailyStreakCount
        self.streakStartedAt = streakStartedAt
        self.lastActiveDate = lastActiveDate
        self.createdAt = .now
        self.updatedAt = .now
    }
}

public extension User {
    var isAdmin: Bool { roles.contains("admin") }

    /// `isPremium`'u tek source of truth olarak kullan; expired ise false dön.
    var hasActivePremium: Bool {
        guard isPremium else { return false }
        if let end = subscriptionEndDate, end < .now {
            return false
        }
        return true
    }
}
