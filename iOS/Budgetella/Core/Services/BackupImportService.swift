//
//  BackupImportService.swift
//  Budgetella
//
//  Webapp JSON yedeğini (budgetella_backup_YYYY-MM-DD.json) SwiftData'ya aktarır.
//  Kategori adlarını mevcut CategorySlug'lara eşler; eksik slug → "other" (Diğer).
//

import Foundation
import SwiftData

// MARK: - Decodable backup types

struct BackupFile: Decodable {
    let transactions: [BackupTransaction]
    let version: String?
    let exportDate: String?
}

struct BackupTransaction: Decodable {
    let id: String
    let amount: Double
    let type: String
    let category: String?
    let description: String
    let date: String
    let isRecurring: Bool
    let status: String?
}

// MARK: - Result

struct ImportResult {
    let imported: Int
    let skipped: Int
    let categoriesCreated: Int
}

// MARK: - Service

enum BackupImportService {

    /// Backup JSON → Transaction slug eşlemesi.
    private static let categoryNameToSlug: [String: CategorySlug] = [
        "Maaş":            .salary,
        "Freelance":       .freelance,
        "Serbest Çalışma": .freelance,
        "Sale":            .productSale,
        "Yatırım":         .investments,
        "Hediyeler":       .gifts,
        "Yiyecek":         .food,
        "Ulaşım":          .transportation,
        "Konut":           .housing,
        "Faturalar":       .bills,
        "Utilities":       .bills,
        "Sağlık":          .healthcare,
        "Alışveriş":       .shopping,
        "Eğlence":         .entertainment,
        "Eğitim":          .education,
    ]

    static func importFromURL(
        _ url: URL,
        modelContext: ModelContext,
        userId: String
    ) throws -> ImportResult {

        let data = try Data(contentsOf: url)
        let backup = try JSONDecoder().decode(BackupFile.self, from: data)

        // Fetch existing transactions (for duplicate detection by legacy ID)
        let existingTransactions = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
        let existingNotes = Set(existingTransactions.map { "\($0.note)|\($0.amount)|\($0.date.timeIntervalSince1970.rounded())" })

        // Fetch or build category map
        let existingCategories = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        var categoryCache: [String: Category] = [:]
        for cat in existingCategories {
            categoryCache[cat.name] = cat
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateFormatterSimple = ISO8601DateFormatter()
        dateFormatterSimple.formatOptions = [.withInternetDateTime]

        var imported = 0
        var skipped = 0
        var categoriesCreated = 0

        for raw in backup.transactions {
            let note = raw.description
            let amount = Decimal(raw.amount)

            // Parse date
            let date = dateFormatter.date(from: raw.date)
                ?? dateFormatterSimple.date(from: raw.date)
                ?? Date()

            // Dedup key
            let key = "\(note)|\(amount)|\(date.timeIntervalSince1970.rounded())"
            if existingNotes.contains(key) {
                skipped += 1
                continue
            }

            // Resolve category
            let category: Category? = resolveCategory(
                name: raw.category,
                userId: userId,
                cache: &categoryCache,
                existingAll: existingCategories,
                modelContext: modelContext,
                created: &categoriesCreated
            )

            // Transaction type
            let txType: TransactionType = raw.type == "income" ? .income : .expense
            let txStatus: TransactionStatus = raw.status == "pending" ? .pending : .completed

            let tx = Transaction(
                userId: userId,
                type: txType,
                amount: amount,
                currency: "TRY",
                note: note.isEmpty ? "İsimsiz" : note,
                category: category,
                date: date,
                status: txStatus,
                isRecurring: raw.isRecurring
            )
            modelContext.insert(tx)
            imported += 1
        }

        try modelContext.save()
        return ImportResult(imported: imported, skipped: skipped, categoriesCreated: categoriesCreated)
    }

    private static func resolveCategory(
        name: String?,
        userId: String,
        cache: inout [String: Category],
        existingAll: [Category],
        modelContext: ModelContext,
        created: inout Int
    ) -> Category? {
        guard let name = name, !name.isEmpty else { return nil }

        // Direct name match
        if let cat = cache[name] { return cat }

        // Slug match
        if let slug = categoryNameToSlug[name] {
            let turkishName = slug.turkishName
            if let cat = cache[turkishName] { return cat }

            // Find in existing by slug
            if let cat = existingAll.first(where: { $0.slug == slug.rawValue }) {
                cache[name] = cat
                cache[turkishName] = cat
                return cat
            }
        }

        // Create new category — use Turkish name when slug is known
        let slug = categoryNameToSlug[name]
        let newCat = Category(
            userId: userId,
            name: slug?.turkishName ?? name,
            slug: slug?.rawValue,
            type: slug?.type ?? .expense,
            iconName: slug?.defaultIcon ?? "tag",
            colorHex: slug?.defaultColorHex ?? "#94a3b8",
            isDefault: slug != nil,   // known slug = default category
            sortOrder: 999
        )
        modelContext.insert(newCat)
        cache[name] = newCat
        created += 1
        return newCat
    }
}
