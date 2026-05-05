//
//  WidgetDataManager.swift
//  Budgetella
//
//  App Group'a widget snapshot yazar. Widget extension aynı UserDefaults'u okur.
//  Her transaction save sonrası ve app foreground'a gelince çağrılır.
//

import Foundation
import SwiftData
@preconcurrency import WidgetKit

// MARK: - Shared snapshot (main app tarafı)
// Widget extension'da aynı struct aynı property'lerle tekrar tanımlanır.

struct WidgetSnapshot: Codable {
    var todayExpense: Double
    var todayIncome: Double
    var isPremium: Bool
    var lastUpdated: Date

    static let empty = WidgetSnapshot(
        todayExpense: 0, todayIncome: 0, isPremium: false, lastUpdated: .distantPast
    )
}

// MARK: - Manager

@MainActor
enum WidgetDataManager {

    private static let suiteName = "group.com.ozankilic.budgetella"
    private static let snapshotKey = "budgetella.widgetSnapshot"

    // Bugünkü işlemleri hesapla → App Group'a yaz → WidgetKit timeline'ını yenile
    static func refresh(context: ModelContext, isPremium: Bool) {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let predicate = #Predicate<Transaction> { $0.date >= startOfDay }
        let txs = (try? context.fetch(FetchDescriptor<Transaction>(predicate: predicate))) ?? []

        let expense = txs
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let income = txs
            .filter { $0.type == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }

        let snapshot = WidgetSnapshot(
            todayExpense: NSDecimalNumber(decimal: expense).doubleValue,
            todayIncome: NSDecimalNumber(decimal: income).doubleValue,
            isPremium: isPremium,
            lastUpdated: .now
        )
        write(snapshot)
    }

    // MARK: - Private

    private static func write(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: snapshotKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
