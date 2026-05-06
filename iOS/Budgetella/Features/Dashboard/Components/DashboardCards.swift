//
//  DashboardCards.swift
//  Budgetella
//
//  YearSummaryCard + MonthSummaryCard + DailyFlowChart
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Dashboard Main Card (year + month combined)

struct DashboardMainCard: View {
    let year: Int
    let month: Int
    let yearIncome: Decimal
    let yearExpense: Decimal
    let monthIncome: Decimal
    let monthExpense: Decimal
    let dailyData: [DailyFlowPoint]
    let availableYears: [Int]
    let onYearChange: (Int) -> Void
    let onMonthChange: (Int) -> Void

    @Environment(\.hideAmounts) private var hideAmounts

    private var monthNet: Decimal { monthIncome - monthExpense }
    private var isNegativeNet: Bool { monthNet < 0 }

    private var isCurrentPeriod: Bool {
        let cal = Calendar.current
        return year == cal.component(.year, from: .now) && month == cal.component(.month, from: .now)
    }

    var body: some View {
        VStack(spacing: 0) {
            yearSection
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)

            Divider()
                .background(BrandColor.borderSubtle)
                .padding(.horizontal, Spacing.lg)

            monthSection
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.lg)
        }
        .glassCard(cornerRadius: Spacing.radiusMedium)
    }

    // MARK: - Year section

    private var yearSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("YILLIK ÖZET")
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
                    .tracking(1.2)
                Spacer()
                yearPicker
            }

            HStack(spacing: 0) {
                yearStatColumn(
                    arrow: "arrow.up",
                    label: "GELİR",
                    amount: hideAmounts ? "••••" : yearIncome.compactTRY,
                    color: BrandColor.income
                )
                Divider()
                    .frame(width: 1)
                    .background(BrandColor.borderSubtle)
                    .padding(.vertical, Spacing.xs)
                yearStatColumn(
                    arrow: "arrow.down",
                    label: "GİDER",
                    amount: hideAmounts ? "••••" : yearExpense.compactTRY,
                    color: BrandColor.expense
                )
            }
        }
    }

    private var yearPicker: some View {
        Menu {
            ForEach(availableYears, id: \.self) { y in
                Button(action: { onYearChange(y) }) {
                    Text(verbatim: String(y))
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(verbatim: String(year))
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 5)
            .background(BrandColor.background3)
            .clipShape(Capsule())
        }
    }

    private func yearStatColumn(arrow: String, label: LocalizedStringKey, amount: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: arrow)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
                    .tracking(0.5)
            }
            Text(amount)
                .font(.brand(.displayHero))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.sm)
    }

    // MARK: - Month section

    private var monthSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("AKTİF AY")
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
                    .tracking(1.2)
                Spacer()
                if !isCurrentPeriod {
                    Button {
                        let cal = Calendar.current
                        onMonthChange(cal.component(.month, from: .now))
                    } label: {
                        Text("Bu Ay")
                            .font(.brand(.caption))
                            .foregroundStyle(BrandColor.primary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 4)
                            .background(BrandColor.primary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                monthPicker
            }

            HStack(spacing: 0) {
                monthAmountColumn(
                    arrow: "arrow.up.right",
                    label: "Gelir",
                    amount: hideAmounts ? "••••" : monthIncome.fullTRY,
                    color: BrandColor.income
                )
                monthAmountColumn(
                    arrow: "arrow.down.right",
                    label: "Gider",
                    amount: hideAmounts ? "••••" : monthExpense.fullTRY,
                    color: BrandColor.expense
                )
            }

            HStack(spacing: 4) {
                Image(systemName: isNegativeNet ? "arrow.down" : "arrow.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isNegativeNet ? BrandColor.expense : BrandColor.income)
                Text(hideAmounts ? "Net •••• (\(monthFull(month)))" : "Net \(isNegativeNet ? "−" : "+")\(abs(monthNet).fullTRY) (\(monthFull(month)))")
                    .font(.brand(.footnote))
                    .foregroundStyle(isNegativeNet ? BrandColor.expense : BrandColor.income)
                Spacer()
            }

            VStack(spacing: Spacing.xs) {
                HStack {
                    Text("GÜNLÜK AKIŞ · \(monthFull(month).uppercased())")
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.textTertiary)
                        .tracking(1.0)
                    Spacer()
                    HStack(spacing: Spacing.sm) {
                        legendDot(color: BrandColor.income, label: "Gelir")
                        legendDot(color: BrandColor.expense, label: "Gider")
                    }
                }
                DailyFlowChart(data: dailyData)
            }
        }
    }

    private var availableMonths: [Int] {
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: .now)
        let currentMonth = cal.component(.month, from: .now)
        let maxMonth = year == currentYear ? currentMonth : 12
        return Array(stride(from: maxMonth, through: 1, by: -1))
    }

    private var monthPicker: some View {
        Menu {
            ForEach(availableMonths, id: \.self) { m in
                Button(monthFull(m)) { onMonthChange(m) }
            }
        } label: {
            HStack(spacing: 4) {
                Text(monthFull(month))
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 5)
            .background(BrandColor.background3)
            .clipShape(Capsule())
        }
    }

    private func monthAmountColumn(arrow: String, label: LocalizedStringKey, amount: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: arrow)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            Text(amount)
                .font(.brand(.title))
                .foregroundStyle(color)
                .minimumScaleFactor(0.55)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legendDot(color: Color, label: LocalizedStringKey) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 6)
            Text(label)
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
        }
    }
}

// MARK: - Year Summary Card

struct YearSummaryCard: View {
    let year: Int
    let income: Decimal
    let expense: Decimal
    let availableYears: [Int]
    let onYearChange: (Int) -> Void

    @Environment(\.hideAmounts) private var hideAmounts

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("YILLIK ÖZET")
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
                    .tracking(1.2)
                Spacer()
                yearPicker
            }

            HStack(spacing: 0) {
                statColumn(
                    arrow: "arrow.up",
                    label: "GELİR (YIL)",
                    amount: hideAmounts ? "••••" : income.compactTRY,
                    color: BrandColor.income
                )
                Divider()
                    .frame(width: 1)
                    .background(BrandColor.borderSubtle)
                    .padding(.vertical, Spacing.xs)
                statColumn(
                    arrow: "arrow.down",
                    label: "GİDER (YIL)",
                    amount: hideAmounts ? "••••" : expense.compactTRY,
                    color: BrandColor.expense
                )
            }
        }
        .padding(Spacing.lg)
        .glassCard(cornerRadius: Spacing.radiusMedium)
    }

    private var yearPicker: some View {
        Menu {
            ForEach(availableYears, id: \.self) { y in
                Button(action: { onYearChange(y) }) {
                    Text(verbatim: String(y))
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(verbatim: String(year))
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 5)
            .background(BrandColor.background3)
            .clipShape(Capsule())
        }
    }

    private func statColumn(arrow: String, label: LocalizedStringKey, amount: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: arrow)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
                    .tracking(0.5)
            }
            Text(amount)
                .font(.brand(.displayHero))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.sm)
    }
}

// MARK: - Month Summary Card

struct MonthSummaryCard: View {
    let year: Int
    let month: Int
    let income: Decimal
    let expense: Decimal
    let dailyData: [DailyFlowPoint]
    let onMonthChange: (Int) -> Void

    @Environment(\.hideAmounts) private var hideAmounts

    private var net: Decimal { income - expense }
    private var isNegativeNet: Bool { net < 0 }

    private var isCurrentPeriod: Bool {
        let cal = Calendar.current
        return year == cal.component(.year, from: .now) && month == cal.component(.month, from: .now)
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header
            HStack {
                Text("AKTİF AY")
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
                    .tracking(1.2)
                Spacer()
                if !isCurrentPeriod {
                    Button {
                        let cal = Calendar.current
                        onMonthChange(cal.component(.month, from: .now))
                    } label: {
                        Text("Bu Ay")
                            .font(.brand(.caption))
                            .foregroundStyle(BrandColor.primary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 4)
                            .background(BrandColor.primary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                monthPicker
            }

            // Income / Expense columns
            HStack(spacing: 0) {
                amountColumn(
                    arrow: "arrow.up.right",
                    label: "Gelir",
                    amount: hideAmounts ? "••••" : income.fullTRY,
                    color: BrandColor.income
                )
                amountColumn(
                    arrow: "arrow.down.right",
                    label: "Gider",
                    amount: hideAmounts ? "••••" : expense.fullTRY,
                    color: BrandColor.expense
                )
            }

            // Net
            HStack(spacing: 4) {
                Image(systemName: isNegativeNet ? "arrow.down" : "arrow.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isNegativeNet ? BrandColor.expense : BrandColor.income)
                Text(hideAmounts ? "Net •••• (\(monthFull(month)))" : "Net \(isNegativeNet ? "−" : "+")\((abs(net)).fullTRY) (\(monthFull(month)))")
                    .font(.brand(.footnote))
                    .foregroundStyle(isNegativeNet ? BrandColor.expense : BrandColor.income)
                Spacer()
            }

            // Chart
            VStack(spacing: Spacing.xs) {
                HStack {
                    Text("GÜNLÜK AKIŞ · \(monthFull(month).uppercased())")
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.textTertiary)
                        .tracking(1.0)
                    Spacer()
                    HStack(spacing: Spacing.sm) {
                        legendDot(color: BrandColor.income, label: "Gelir")
                        legendDot(color: BrandColor.expense, label: "Gider")
                    }
                }
                DailyFlowChart(data: dailyData)
            }
        }
        .padding(Spacing.lg)
        .glassCard(cornerRadius: Spacing.radiusMedium)
    }

    private var availableMonths: [Int] {
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: .now)
        let currentMonth = cal.component(.month, from: .now)
        let maxMonth = year == currentYear ? currentMonth : 12
        return Array(stride(from: maxMonth, through: 1, by: -1))
    }

    private var monthPicker: some View {
        Menu {
            ForEach(availableMonths, id: \.self) { m in
                Button(monthFull(m)) { onMonthChange(m) }
            }
        } label: {
            HStack(spacing: 4) {
                Text(monthFull(month))
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 5)
            .background(BrandColor.background3)
            .clipShape(Capsule())
        }
    }

    private func amountColumn(arrow: String, label: LocalizedStringKey, amount: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: arrow)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            Text(amount)
                .font(.brand(.title))
                .foregroundStyle(color)
                .minimumScaleFactor(0.55)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legendDot(color: Color, label: LocalizedStringKey) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 6)
            Text(label)
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
        }
    }
}

// MARK: - Daily Flow Chart

struct DailyFlowChart: View {
    let data: [DailyFlowPoint]

    var body: some View {
        if data.isEmpty {
            RoundedRectangle(cornerRadius: 4)
                .fill(BrandColor.borderSubtle.opacity(0.3))
                .frame(height: 72)
                .overlay(
                    Text("Veri yok")
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.textTertiary)
                )
        } else {
            Chart(data) { point in
                LineMark(
                    x: .value(String(localized: "Gün"), point.day),
                    y: .value(String(localized: "Tutar"), point.amount)
                )
                .foregroundStyle(by: .value(String(localized: "Tür"), point.kind == .income ? String(localized: "Gelir") : String(localized: "Gider")))
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
            .chartForegroundStyleScale([
                String(localized: "Gelir"): BrandColor.income,
                String(localized: "Gider"): BrandColor.expense
            ])
            .chartLegend(.hidden)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 72)
        }
    }
}

// MARK: - Income vs Expense Bar Chart (Last 6 Months)

struct IncomeExpenseBarChart: View {
    let data: [MonthlyFlowPoint]

    private var incomeLabel: String { String(localized: "Gelir") }
    private var expenseLabel: String { String(localized: "Gider") }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Header
            HStack {
                Text("GELİR & GİDER")
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
                    .tracking(1.2)
                Spacer()
                HStack(spacing: Spacing.sm) {
                    legendPill(color: BrandColor.income, label: "Gelir")
                    legendPill(color: BrandColor.expense, label: "Gider")
                }
            }

            if data.isEmpty {
                RoundedRectangle(cornerRadius: 4)
                    .fill(BrandColor.borderSubtle.opacity(0.3))
                    .frame(height: 140)
                    .overlay(
                        Text("Veri yok")
                            .font(.brand(.caption))
                            .foregroundStyle(BrandColor.textTertiary)
                    )
            } else {
                Chart(data) { point in
                    let label = point.kind == .income ? incomeLabel : expenseLabel
                    BarMark(
                        x: .value(String(localized: "Ay"), monthShort(point.month)),
                        y: .value(String(localized: "Tutar"), point.amount),
                        width: .ratio(0.75)
                    )
                    .foregroundStyle(by: .value("Tür", label))
                    .position(by: .value("Tür", label))
                    .cornerRadius(4)
                }
                .chartForegroundStyleScale([
                    incomeLabel:  BrandColor.income,
                    expenseLabel: BrandColor.expense
                ])
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .font(.brand(.caption))
                            .foregroundStyle(BrandColor.textTertiary)
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 140)
            }
        }
        .padding(Spacing.lg)
        .glassCard(cornerRadius: Spacing.radiusMedium)
    }

    private func legendPill(color: Color, label: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 6)
            Text(label)
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
        }
    }
}

// MARK: - AI Insight Card

struct AIInsightCard: View {

    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @State private var pickedIndex = 0

    private var allInsights: [(tag: String, text: String, accentColor: Color)] {
        var result: [(tag: String, text: String, accentColor: Color)] = []
        if let cached = GeminiInsightService.cachedInsights() {
            result += cached.map { ($0.tag, $0.text, accentColorFor($0.accent)) }
        }
        let ruleBased = BudgiInsightEngine.compute(transactions: transactions, categories: categories)
        result += ruleBased.map { ($0.tag, $0.text, $0.accentColor) }
        return result
    }

    private var displayInsight: (tag: String, text: String, accentColor: Color) {
        guard !allInsights.isEmpty else {
            return ("BUDGİ · AI", "Harcama verilerin analiz edilmeye hazır. Birkaç işlem ekledikten sonra kişisel öneriler buraya gelecek.", BrandColor.primary)
        }
        return allInsights[pickedIndex % allInsights.count]
    }

    private func accentColorFor(_ key: String) -> Color {
        switch key {
        case "income":  return BrandColor.income
        case "expense": return BrandColor.expense
        case "warning": return BrandColor.warning
        case "info":    return BrandColor.info
        default:        return BrandColor.primary
        }
    }

    var body: some View {
        let insight = displayInsight
        HStack(spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: 2)
                .fill(insight.accentColor)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: Spacing.sm) {
                    HStack(spacing: 3) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(BrandColor.primary)
                        Text("BUDGİ · AI")
                            .font(.brand(.caption))
                            .foregroundStyle(BrandColor.primary)
                            .tracking(0.8)
                    }
                    Spacer()
                    Text(LocalizedStringKey(insight.tag))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(insight.accentColor)
                        .clipShape(Capsule())
                }
                Text(insight.text)
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }
        }
        .padding(Spacing.lg)
        .glassCard(cornerRadius: Spacing.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                .strokeBorder(BrandColor.primary.opacity(0.25), lineWidth: 1)
        )
        .onAppear {
            let count = allInsights.count
            if count > 1 { pickedIndex = Int.random(in: 0..<count) }
        }
    }
}
