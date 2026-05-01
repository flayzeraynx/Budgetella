//
//  NotificationRecord.swift
//  Budgetella
//
//  Bildirim kutusu (inbox) için lokal kayıt.
//  `Notification` adı Foundation.Notification ile çakışır — `NotificationRecord` kullanılır.
//  Push payload'ı oluşturulduğunda bu kayıt da eklenir (Firebase Functions → lokal mirror).
//

import Foundation
import SwiftData

/// Bildirim tipi — deep link hedefini ve içeriği belirler.
public enum NotificationKind: String, Codable, CaseIterable, Sendable {
    /// Haftalık Özet ekranına yönlendirir.
    case weeklyDigest    = "weekly_digest"
    /// İlgili bütçe detay ekranına yönlendirir.
    case budgetAlert     = "budget_alert"
    /// Anomali tespiti — ilgili işlem detayına yönlendirir.
    case anomaly         = "anomaly"
    /// Achievement unlock — profil/gamification ekranına yönlendirir.
    case achievement     = "achievement"
    /// Hedef milestone (örn. %50, %100) — hedef detayına yönlendirir.
    case goalMilestone   = "goal_milestone"
    /// Genel sistem mesajı — deep link yok.
    case systemMessage   = "system_message"
}

@Model
public final class NotificationRecord {

    @Attribute(.unique) public var id: UUID
    public var userId: String

    public var typeRaw: String
    public var title: String
    public var body: String

    /// Uygulama içi navigasyon hedefi. Örn: "budgetella://budget/uuid-here"
    /// Nil ise bildirim tıklanınca ekstra navigasyon yok.
    public var deepLink: String?

    public var isRead: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        userId: String,
        kind: NotificationKind,
        title: String,
        body: String,
        deepLink: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.typeRaw = kind.rawValue
        self.title = title
        self.body = body
        self.deepLink = deepLink
        self.isRead = false
        self.createdAt = .now
    }
}

public extension NotificationRecord {
    var kind: NotificationKind {
        NotificationKind(rawValue: typeRaw) ?? .systemMessage
    }

    /// SF Symbol adı — bildirim listesinde ikon olarak kullanılır.
    var iconName: String {
        switch kind {
        case .weeklyDigest:  return "chart.bar.doc.horizontal"
        case .budgetAlert:   return "exclamationmark.triangle.fill"
        case .anomaly:       return "waveform.badge.exclamationmark"
        case .achievement:   return "trophy.fill"
        case .goalMilestone: return "target"
        case .systemMessage: return "bell.fill"
        }
    }
}
