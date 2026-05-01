//
//  Category.swift
//  Budgetella
//
//  SwiftData @Model — gelir/gider kategorisi.
//  Default 12 kategori onboarding'de seed ediliyor; custom kategoriler premium gated.
//  i18n display name AppSettings.language'e göre Localizable.xcstrings'ten okunur,
//  burada sadece slug/raw key tutulur.
//

import Foundation
import SwiftData

@Model
public final class Category {

    @Attribute(.unique) public var id: UUID
    public var userId: String

    /// Lokalize edilebilir slug. Default kategoriler için CategorySlug raw value;
    /// custom kategoriler için doğrudan kullanıcı girişi.
    public var name: String
    /// Default kategoriler için CategorySlug.rawValue. Custom kategorilerde nil.
    public var slug: String?

    public var type: TransactionType
    public var iconName: String   // SF Symbol adı
    public var colorHex: String   // "#RRGGBB"

    public var isDefault: Bool
    public var sortOrder: Int

    public var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    public var transactions: [Transaction] = []

    public init(
        id: UUID = UUID(),
        userId: String,
        name: String,
        slug: String? = nil,
        type: TransactionType,
        iconName: String = "tag",
        colorHex: String = "#6366f1",
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.slug = slug
        self.type = type
        self.iconName = iconName
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.createdAt = .now
    }
}

public extension Category {
    /// Onboarding'de seed edilecek default kategoriler.
    /// CategorySlug + iconName + colorHex KeywordCategorizer'dan geliyor.
    static func seedDefaults(for userId: String) -> [Category] {
        CategorySlug.allCases.enumerated().map { index, slug in
            Category(
                userId: userId,
                name: slug.turkishName,
                slug: slug.rawValue,
                type: slug.type,
                iconName: slug.defaultIcon,
                colorHex: slug.defaultColorHex,
                isDefault: true,
                sortOrder: index
            )
        }
    }
}
