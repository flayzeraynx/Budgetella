//
//  Achievement.swift
//  Budgetella
//
//  Profile gamification — V1'de aktif (Ozzy kararı 2026-05-01).
//  Streak alanları User modelinde, badge'ler bu @Model'da tutulur.
//
//  Unlock mekanizması: BackgroundTaskService veya Dashboard mount'unda
//  AchievementEngine evaluator çalışır, koşul karşılanırsa `unlockedAt = .now` set edilir.
//  Display name/description Localizable.xcstrings'ten okunur ("badge.<rawValue>.title").
//

import Foundation
import SwiftData

public enum BadgeType: String, Codable, CaseIterable, Sendable {

    /// İlk işlem girilince.
    case firstTransaction
    /// 7 gün üst üste aktif.
    case weekStreak
    /// 30 gün üst üste aktif.
    case monthStreak
    /// 365 gün üst üste aktif.
    case yearStreak
    /// 5+ farklı kategoride işlem.
    case categoryExplorer
    /// İlk fiş tarama (premium feature açıldıktan sonra).
    case receiptScanner
    /// İlk sesli işlem girişi (V1.1+ Voice Input açılınca).
    case voiceFirst
    /// Bir ayı bütçe içinde tamamla.
    case budgetMaster
    /// 100+ işlem.
    case transactionCenturion
    /// 1000+ işlem.
    case transactionVeteran

    public var defaultIcon: String {
        switch self {
        case .firstTransaction:     return "sparkles"
        case .weekStreak:           return "flame"
        case .monthStreak:          return "flame.fill"
        case .yearStreak:           return "crown.fill"
        case .categoryExplorer:     return "square.grid.3x3.fill"
        case .receiptScanner:       return "doc.text.viewfinder"
        case .voiceFirst:           return "mic.fill"
        case .budgetMaster:         return "target"
        case .transactionCenturion: return "100.circle.fill"
        case .transactionVeteran:   return "star.circle.fill"
        }
    }

    /// Brand color tone — Achievement card'ında kullanılır.
    public var defaultColorHex: String {
        switch self {
        case .firstTransaction:     return "#6E5BFF"  // brand primary
        case .weekStreak:           return "#F59E0B"
        case .monthStreak:          return "#EF4444"
        case .yearStreak:           return "#FBBF24"  // gold
        case .categoryExplorer:     return "#10B981"
        case .receiptScanner:       return "#06B6D4"
        case .voiceFirst:           return "#8B6FFF"
        case .budgetMaster:         return "#22C55E"
        case .transactionCenturion: return "#3B82F6"
        case .transactionVeteran:   return "#A855F7"
        }
    }

    /// Localizable.xcstrings key: "badge.<rawValue>.title" / ".description".
    public var titleKey: String { "badge.\(rawValue).title" }
    public var descriptionKey: String { "badge.\(rawValue).description" }
}

@Model
public final class Achievement {

    @Attribute(.unique) public var id: UUID
    public var userId: String
    public var badgeRaw: String

    /// `nil` = locked. Set edilince achievement unlock olmuş demektir.
    public var unlockedAt: Date?

    /// 0.0 - 1.0 arası ilerleme. Locked'da progress göstergesi (örn: "5/7 gün streak").
    public var progress: Double

    /// Kullanıcı achievement notification'ı gördü mü (badge dot için).
    public var seen: Bool

    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        userId: String,
        badge: BadgeType,
        unlockedAt: Date? = nil,
        progress: Double = 0,
        seen: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.badgeRaw = badge.rawValue
        self.unlockedAt = unlockedAt
        self.progress = max(0, min(1, progress))
        self.seen = seen
        self.createdAt = .now
    }
}

public extension Achievement {
    var badge: BadgeType {
        BadgeType(rawValue: badgeRaw) ?? .firstTransaction
    }

    var isUnlocked: Bool {
        unlockedAt != nil
    }

    /// Yeni kullanıcı için tüm badge'leri locked seed et.
    static func seedLocked(for userId: String) -> [Achievement] {
        BadgeType.allCases.map { Achievement(userId: userId, badge: $0) }
    }
}
