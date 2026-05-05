//
//  TransactionsViewModel.swift
//  Budgetella
//

import Foundation

@MainActor @Observable final class TransactionsViewModel {

    var searchText     = ""
    var typeFilter: TransactionType? = nil
    var categoryFilter: UUID?

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

    // MARK: - Hierarchical grouping (Year → Month → Day)

    func groupedHierarchical(_ txs: [Transaction]) -> [TransactionYearGroup] {
        let cal = Calendar.current
        let filtered = filtered(txs)

        let byYear = Dictionary(grouping: filtered) { tx in
            cal.component(.year, from: tx.date)
        }

        return byYear.keys.sorted(by: >).map { year in
            let yearTxs = byYear[year]!

            let byMonth = Dictionary(grouping: yearTxs) { tx in
                cal.component(.month, from: tx.date)
            }

            let months = byMonth.keys.sorted(by: >).map { month in
                let monthTxs = byMonth[month]!

                let byDay = Dictionary(grouping: monthTxs) { tx in
                    cal.startOfDay(for: tx.date)
                }

                let fmt = DateFormatter()
                fmt.locale = Locale.current
                fmt.dateFormat = "d MMMM"

                let days = byDay.keys.sorted(by: >).map { date in
                    TransactionDayGroup(
                        id: date.timeIntervalSince1970.description,
                        date: date,
                        title: fmt.string(from: date),
                        transactions: byDay[date]!.sorted { $0.date > $1.date }
                    )
                }

                return TransactionMonthGroup(id: "\(year)-\(month)", month: month, year: year, days: days)
            }

            return TransactionYearGroup(id: year, year: year, months: months)
        }
    }
}

// MARK: - Hierarchical group models

struct TransactionYearGroup: Identifiable {
    let id: Int
    let year: Int
    let months: [TransactionMonthGroup]
}

struct TransactionMonthGroup: Identifiable {
    let id: String
    let month: Int
    let year: Int
    let days: [TransactionDayGroup]
}

struct TransactionDayGroup: Identifiable {
    let id: String
    let date: Date
    let title: String
    let transactions: [Transaction]
}
