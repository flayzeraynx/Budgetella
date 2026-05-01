//
//  TransactionsViewModel.swift
//  Budgetella
//

import Foundation

@MainActor @Observable final class TransactionsViewModel {

    var searchText     = ""
    var typeFilter: TransactionType? = nil  // nil = Tümü
    var categoryFilter: UUID?               // nil = all categories

    // MARK: - Filtering

    func filtered(_ txs: [Transaction]) -> [Transaction] {
        txs.filter { tx in
            let matchesType    = typeFilter == nil || tx.type == typeFilter
            let matchesCat     = categoryFilter == nil || tx.category?.id == categoryFilter
            let matchesSearch  = searchText.isEmpty ||
                tx.note.localizedCaseInsensitiveContains(searchText) ||
                (tx.category?.name.localizedCaseInsensitiveContains(searchText) == true)
            return matchesType && matchesCat && matchesSearch
        }
    }

    func grouped(_ txs: [Transaction]) -> [TransactionSection] {
        let cal = Calendar.current
        let byDay = Dictionary(grouping: filtered(txs)) { tx in
            cal.startOfDay(for: tx.date)
        }
        return byDay.keys.sorted(by: >).map { date in
            let dayTxs = byDay[date]!.sorted { $0.date > $1.date }
            let net = dayTxs.reduce(Decimal(0)) { $0 + $1.signedAmount }
            return TransactionSection(
                id: date.timeIntervalSince1970.description,
                title: sectionTitle(for: date, cal: cal),
                netAmount: net,
                transactions: dayTxs
            )
        }
    }

    private func sectionTitle(for date: Date, cal: Calendar) -> String {
        if cal.isDateInToday(date)     { return "BUGÜN" }
        if cal.isDateInYesterday(date) { return "DÜN" }
        if cal.isDate(date, equalTo: .now, toGranularity: .weekOfYear) {
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "tr_TR")
            fmt.dateFormat = "EEEE"
            return fmt.string(from: date).uppercased()
        }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "tr_TR")
        fmt.dateFormat = "d MMM"
        return fmt.string(from: date).uppercased()
    }
}

struct TransactionSection: Identifiable {
    let id: String
    let title: String
    let netAmount: Decimal
    let transactions: [Transaction]
}
