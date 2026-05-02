//
//  BackupExportService.swift
//  Budgetella
//
//  SwiftData → JSON yedeği. Webapp format'ıyla uyumlu.
//

import Foundation
import SwiftData

enum BackupExportService {

    struct ExportFile: Encodable {
        let version: String
        let exportDate: String
        let transactionCount: Int
        let transactions: [ExportTransaction]
    }

    struct ExportTransaction: Encodable {
        let id: String
        let amount: Double
        let type: String
        let category: String?
        let description: String
        let date: String
        let isRecurring: Bool
        let status: String
    }

    static func export(from modelContext: ModelContext) throws -> URL {
        let txs = (try? modelContext.fetch(FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\Transaction.date, order: .reverse)]
        ))) ?? []

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        let exportTxs = txs.map { tx in
            ExportTransaction(
                id: tx.id.uuidString,
                amount: (tx.amount as NSDecimalNumber).doubleValue,
                type: tx.type == .income ? "income" : "expense",
                category: tx.category?.name,
                description: tx.note,
                date: formatter.string(from: tx.date),
                isRecurring: tx.isRecurring,
                status: tx.status == .pending ? "pending" : "completed"
            )
        }

        let dateStr = formatter.string(from: .now).prefix(10)
        let file = ExportFile(
            version: "2.0",
            exportDate: String(dateStr),
            transactionCount: exportTxs.count,
            transactions: exportTxs
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(file)

        let fileName = "budgetella_backup_\(dateStr).json"
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: tmpURL)
        return tmpURL
    }
}
