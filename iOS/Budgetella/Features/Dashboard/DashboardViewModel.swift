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
        switch Calendar.current.component(.hour, from: .now) {
        case 6..<12:  return "Günaydın,"
        case 12..<17: return "İyi günler,"
        case 17..<22: return "İyi akşamlar,"
        default:      return "İyi geceler,"
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

    // MARK: - Available periods

    var availableYears: [Int] {
        let current = Calendar.current.component(.year, from: .now)
        return Array(stride(from: current, through: current - 5, by: -1))
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
    var compactTRY: String {
        let d = (self as NSDecimalNumber).doubleValue
        switch abs(d) {
        case 1_000_000...: return String(format: "₺%.2fM", d / 1_000_000)
        case 1_000...:     return String(format: "₺%.1fB", d / 1_000)
        default:           return String(format: "₺%.0f", d)
        }
    }

    var fullTRY: String {
        let d = (self as NSDecimalNumber).doubleValue
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.minimumFractionDigits = 0
        fmt.maximumFractionDigits = 0
        fmt.groupingSeparator = "."
        let s = fmt.string(from: NSNumber(value: d)) ?? "0"
        return "₺\(s)"
    }
}

// MARK: - Month name helpers

func turkishMonthShort(_ month: Int) -> String {
    let names = ["Oca","Şub","Mar","Nis","May","Haz","Tem","Ağu","Eyl","Eki","Kas","Ara"]
    guard (1...12).contains(month) else { return "" }
    return names[month - 1]
}

func turkishMonthFull(_ month: Int) -> String {
    let names = ["Ocak","Şubat","Mart","Nisan","Mayıs","Haziran","Temmuz","Ağustos","Eylül","Ekim","Kasım","Aralık"]
    guard (1...12).contains(month) else { return "" }
    return names[month - 1]
}
