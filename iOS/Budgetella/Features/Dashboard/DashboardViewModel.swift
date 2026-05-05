//
//  DashboardViewModel.swift
//  Budgetella
//
//  Dashboard UI state + transaction aggregation.
//  Transactions @Query'den View'dan geçirilir — SwiftData + @Observable pattern.
//

import Foundation

@MainActor @Observable final class DashboardViewModel {

    var selectedYear: Int
    var selectedMonth: Int

    init() {
        let comps = Calendar.current.dateComponents([.year, .month], from: .now)
        selectedYear = comps.year ?? 2026
        selectedMonth = comps.month ?? 1
    }

    // MARK: - Greeting

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 6..<12:  return LocaleHelper.string("Günaydın,")
        case 12..<17: return LocaleHelper.string("İyi günler,")
        case 17..<22: return LocaleHelper.string("İyi akşamlar,")
        default:      return LocaleHelper.string("İyi geceler,")
        }
    }

    // MARK: - Yearly aggregates

    func yearlyIncome(from txs: [Transaction]) -> Decimal {
        txs.filter { $0.type == .income && calYear($0) == selectedYear }
           .reduce(0) { $0 + $1.amount }
    }

    func yearlyExpense(from txs: [Transaction]) -> Decimal {
        txs.filter { $0.type == .expense && calYear($0) == selectedYear }
           .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Monthly aggregates

    func monthlyIncome(from txs: [Transaction]) -> Decimal {
        txs.filter { $0.type == .income && calYear($0) == selectedYear && calMonth($0) == selectedMonth }
           .reduce(0) { $0 + $1.amount }
    }

    func monthlyExpense(from txs: [Transaction]) -> Decimal {
        txs.filter { $0.type == .expense && calYear($0) == selectedYear && calMonth($0) == selectedMonth }
           .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Daily flow for chart

    func dailyFlowData(from txs: [Transaction]) -> [DailyFlowPoint] {
        let cal = Calendar.current
        guard let selectedDate = cal.date(from: DateComponents(year: selectedYear, month: selectedMonth)),
              let daysInMonth = cal.range(of: .day, in: .month, for: selectedDate)?.count
        else { return [] }

        let monthTxs = txs.filter { calYear($0) == selectedYear && calMonth($0) == selectedMonth }

        return (1...daysInMonth).flatMap { day -> [DailyFlowPoint] in
            let dayTxs = monthTxs.filter { cal.component(.day, from: $0.date) == day }
            let inc = dayTxs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let exp = dayTxs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            return [
                DailyFlowPoint(day: day, kind: .income,  amount: (inc as NSDecimalNumber).doubleValue),
                DailyFlowPoint(day: day, kind: .expense, amount: (exp as NSDecimalNumber).doubleValue)
            ]
        }
    }

    // MARK: - Month-over-month change

    func percentChange(from txs: [Transaction]) -> Double? {
        let thisMonth = monthlyExpense(from: txs)
        let prevMonth: Int
        let prevYear: Int
        if selectedMonth == 1 {
            prevMonth = 12
            prevYear = selectedYear - 1
        } else {
            prevMonth = selectedMonth - 1
            prevYear = selectedYear
        }
        let prevExpense = txs
            .filter { $0.type == .expense && calYear($0) == prevYear && calMonth($0) == prevMonth }
            .reduce(Decimal(0)) { $0 + $1.amount }
        guard prevExpense > 0 else { return nil }
        let diff = (thisMonth - prevExpense) as NSDecimalNumber
        let prev = prevExpense as NSDecimalNumber
        return diff.doubleValue / prev.doubleValue * 100
    }

    // MARK: - Available periods

    func availableYears(from txs: [Transaction]) -> [Int] {
        let current = Calendar.current.component(.year, from: .now)
        var years = Set(txs.map { Calendar.current.component(.year, from: $0.date) })
        years.insert(current)
        return years.sorted(by: >)
    }

    // MARK: - Helpers

    private func calYear(_ tx: Transaction) -> Int {
        Calendar.current.component(.year, from: tx.date)
    }

    private func calMonth(_ tx: Transaction) -> Int {
        Calendar.current.component(.month, from: tx.date)
    }
}

// MARK: - Chart data point

struct DailyFlowPoint: Identifiable {
    let id = UUID()
    let day: Int
    let kind: TransactionType
    let amount: Double
}

// MARK: - Decimal formatting

extension Decimal {
    /// Currency symbol read at runtime from UserDefaults so it reflects the
    /// user's in-app currency selection without needing AppSettings in scope.
    private static var currencySymbol: String {
        UserDefaults.standard.string(forKey: "selectedCurrencySymbol") ?? "₺"
    }

    var compactTRY: String {
        let sym = Decimal.currencySymbol
        let d = (self as NSDecimalNumber).doubleValue
        switch abs(d) {
        case 1_000_000...: return String(format: "\(sym)%.2fM", d / 1_000_000)
        case 1_000...:     return String(format: "\(sym)%.1fB", d / 1_000)
        default:           return String(format: "\(sym)%.0f", d)
        }
    }

    var fullTRY: String {
        let sym = Decimal.currencySymbol
        let d = (self as NSDecimalNumber).doubleValue
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.minimumFractionDigits = 0
        fmt.maximumFractionDigits = 0
        fmt.groupingSeparator = "."
        let s = fmt.string(from: NSNumber(value: d)) ?? "0"
        return "\(sym)\(s)"
    }
}

// MARK: - Month name helpers

func monthShort(_ month: Int) -> String {
    let formatter = DateFormatter()
    formatter.locale = LocaleHelper.currentLocale
    guard (1...12).contains(month) else { return "" }
    return formatter.shortMonthSymbols[month - 1]
}

func monthFull(_ month: Int) -> String {
    let formatter = DateFormatter()
    formatter.locale = LocaleHelper.currentLocale
    guard (1...12).contains(month) else { return "" }
    return formatter.monthSymbols[month - 1]
}

// Compatibility shims — call site renames handled in each view file.
@available(*, deprecated, renamed: "monthShort")
func turkishMonthShort(_ month: Int) -> String { monthShort(month) }

@available(*, deprecated, renamed: "monthFull")
func turkishMonthFull(_ month: Int) -> String { monthFull(month) }
