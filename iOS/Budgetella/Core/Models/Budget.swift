//
//  Budget.swift
//  Budgetella
//
//  Kullanıcının belirli bir kategori için aylık bütçe limiti.
//  Her ay/yıl/kategori kombinasyonu için bir kayıt (unique değil ama
//  BudgetService seviyesinde duplicate check uygulanır).
//

import Foundation
import SwiftData

@Model
public final class Budget {

    @Attribute(.unique) public var id: UUID
    public var userId: String

    /// Bağlı kategori slug'ı (CategorySlug.rawValue).
    /// Relationship yerine slug kullanılıyor — kategoriler silinse bile
    /// bütçe kaydı geçmişte kalabilmeli.
    public var categorySlug: String

    /// Bütçe limiti (pozitif).
    public var amount: Decimal
    public var currency: String

    /// 1-12
    public var month: Int
    /// Örn. 2026
    public var year: Int

    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        userId: String,
        categorySlug: String,
        amount: Decimal,
        currency: String = "TRY",
        month: Int,
        year: Int
    ) {
        self.id = id
        self.userId = userId
        self.categorySlug = categorySlug
        self.amount = amount
        self.currency = currency
        self.month = month
        self.year = year
        self.createdAt = .now
        self.updatedAt = .now
    }
}

public extension Budget {
    /// "2026-05" formatında benzersiz anahtar — cache ve lookup için.
    var monthKey: String {
        String(format: "%04d-%02d", year, month)
    }

    /// Bu bütçe şu anki ay/yıl için mi?
    var isCurrentMonth: Bool {
        let now = Calendar.current.dateComponents([.month, .year], from: .now)
        return month == now.month && year == now.year
    }
}
