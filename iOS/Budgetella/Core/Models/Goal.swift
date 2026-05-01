//
//  Goal.swift
//  Budgetella
//
//  Tasarruf hedefi. V1 scope kararları:
//  - "Otomatik birikim" toggle → YOK (V1.1+)
//  - Demo/preview tutarı: ₺90.000 (V2.1 PDF'teki ₺50.000 ignore edildi)
//  - isArchived field var ama V1 UI'da kullanılmıyor; gerçek sil = sil.
//

import Foundation
import SwiftData

/// Önceden tanımlı hedef şablonları — onboarding veya hedef kurulum ekranında seçilir.
public enum GoalTemplate: String, Codable, CaseIterable, Sendable {
    case emergencyFund = "emergency_fund"   // Acil durum fonu
    case vacation      = "vacation"         // Tatil
    case education     = "education"        // Eğitim
    case technology    = "technology"       // Teknoloji
    case vehicle       = "vehicle"          // Araç
    case home          = "home"             // Ev/konut
    case custom        = "custom"           // Özel

    public var defaultIcon: String {
        switch self {
        case .emergencyFund: return "sos"
        case .vacation:      return "airplane"
        case .education:     return "graduationcap.fill"
        case .technology:    return "laptopcomputer"
        case .vehicle:       return "car.fill"
        case .home:          return "house.fill"
        case .custom:        return "star.fill"
        }
    }

    public var localizedKey: String {
        "goal.template.\(rawValue)"
    }
}

@Model
public final class Goal {

    @Attribute(.unique) public var id: UUID
    public var userId: String

    public var name: String
    public var targetAmount: Decimal
    /// Manuel eklenen toplam birikim. "Birikim ekle" CTA'sı bu değeri artırır.
    public var currentAmount: Decimal
    public var currency: String

    public var deadline: Date?
    /// SF Symbol adı veya emoji string.
    public var iconName: String
    /// GoalTemplate.rawValue veya nil (custom).
    public var templateSlug: String?

    /// V1'de hard delete kullanılıyor; bu field V1.1+ soft-delete için rezerve.
    public var isArchived: Bool

    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        userId: String,
        name: String,
        targetAmount: Decimal,
        currentAmount: Decimal = 0,
        currency: String = "TRY",
        deadline: Date? = nil,
        iconName: String = "star.fill",
        templateSlug: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.currency = currency
        self.deadline = deadline
        self.iconName = iconName
        self.templateSlug = templateSlug
        self.isArchived = false
        self.createdAt = .now
        self.updatedAt = .now
    }
}

public extension Goal {
    /// 0.0 – 1.0 arasında ilerleme. 1.0'ı geçmez.
    var progressPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        let pct = (NSDecimalNumber(decimal: currentAmount).doubleValue /
                   NSDecimalNumber(decimal: targetAmount).doubleValue)
        return min(pct, 1.0)
    }

    var remainingAmount: Decimal {
        max(targetAmount - currentAmount, 0)
    }

    var isCompleted: Bool {
        currentAmount >= targetAmount
    }

    /// Hedefe ulaşmak için kalan gün sayısı. deadline yoksa nil.
    var daysRemaining: Int? {
        guard let deadline else { return nil }
        let days = Calendar.current.dateComponents([.day], from: .now, to: deadline).day ?? 0
        return max(days, 0)
    }

    /// Günlük birikim gereksinimi. Deadline ve kalan tutar bilinmiyorsa nil.
    var dailyRequiredAmount: Decimal? {
        guard let days = daysRemaining, days > 0 else { return nil }
        return remainingAmount / Decimal(days)
    }
}
