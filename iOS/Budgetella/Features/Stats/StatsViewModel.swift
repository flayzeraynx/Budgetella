//
//  StatsViewModel.swift
//  Budgetella
//

import Foundation

@MainActor @Observable final class StatsViewModel {

    var selectedYear: Int
    var selectedMonth: Int
    var selectedSegment: Segment = .genel

    enum Segment: String, CaseIterable {
        case genel   = "Genel"
        case butce   = "Bütçe"
        case tahmin  = "Tahmin"
    }

    init() {
        let comps = Calendar.current.dateComponents([.year, .month], from: .now)
        selectedYear  = comps.year  ?? 2026
        selectedMonth = comps.month ?? 1
    }

    // MARK: - Aggregates

    func totalExpense(from txs: [Transaction]) -> Decimal {
        txs.filter { $0.type == .expense && inPeriod($0) }.reduce(0) { $0 + $1.amount }
    }

    func totalIncome(from txs: [Transaction]) -> Decimal {
        txs.filter { $0.type == .income && inPeriod($0) }.reduce(0) { $0 + $1.amount }
    }

    func previousMonthExpense(from txs: [Transaction]) -> Decimal {
        txs.filter { $0.type == .expense && inPreviousPeriod($0) }.reduce(0) { $0 + $1.amount }
    }

    func percentChange(from txs: [Transaction]) -> Double? {
        let current  = (totalExpense(from: txs) as NSDecimalNumber).doubleValue
        let previous = (previousMonthExpense(from: txs) as NSDecimalNumber).doubleValue
        guard previous > 0 else { return nil }
        return ((current - previous) / previous) * 100
    }

    func categoryBreakdown(from txs: [Transaction], categories: [Category]) -> [CategoryStat] {
        breakdown(type: .expense, from: txs, categories: categories)
    }

    func incomBreakdown(from txs: [Transaction], categories: [Category]) -> [CategoryStat] {
        breakdown(type: .income, from: txs, categories: categories)
    }

    private func breakdown(type: TransactionType, from txs: [Transaction], categories: [Category]) -> [CategoryStat] {
        let filtered = txs.filter { $0.type == type && inPeriod($0) }
        let total = filtered.reduce(Decimal(0)) { $0 + $1.amount }
        guard total > 0 else { return [] }

        var dict: [UUID: Decimal] = [:]
        for tx in filtered {
            guard let cat = tx.category else { continue }
            dict[cat.id, default: 0] += tx.amount
        }

        return categories.compactMap { cat -> CategoryStat? in
            guard let amount = dict[cat.id], amount > 0 else { return nil }
            let pct = Double(truncating: (amount / total) as NSDecimalNumber)
            return CategoryStat(category: cat, amount: amount, percentage: pct)
        }
        .sorted { $0.amount > $1.amount }
    }

    var availableYears: [Int] {
        let y = Calendar.current.component(.year, from: .now)
        return Array(stride(from: y, through: y - 4, by: -1))
    }

    func autoSelectPeriod(from txs: [Transaction]) {
        guard !txs.isEmpty else { return }
        guard !txs.contains(where: { inPeriod($0) }) else { return }
        let cal = Calendar.current
        if let latest = txs.max(by: { $0.date < $1.date }) {
            selectedYear  = cal.component(.year,  from: latest.date)
            selectedMonth = cal.component(.month, from: latest.date)
        }
    }

    // MARK: - Helpers

    private func inPeriod(_ tx: Transaction) -> Bool {
        let cal = Calendar.current
        return cal.component(.year,  from: tx.date) == selectedYear &&
               cal.component(.month, from: tx.date) == selectedMonth
    }

    private func inPreviousPeriod(_ tx: Transaction) -> Bool {
        let cal = Calendar.current
        let comps = DateComponents(year: selectedYear, month: selectedMonth)
        guard let current = cal.date(from: comps),
              let prev    = cal.date(byAdding: .month, value: -1, to: current)
        else { return false }
        return cal.component(.year,  from: tx.date) == cal.component(.year,  from: prev) &&
               cal.component(.month, from: tx.date) == cal.component(.month, from: prev)
    }
}

struct CategoryStat: Identifiable {
    let id = UUID()
    let category: Category
    let amount: Decimal
    let percentage: Double
}
