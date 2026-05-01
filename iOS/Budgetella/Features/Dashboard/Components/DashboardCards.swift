//
//  DashboardCards.swift
//  Budgetella
//
//  YearSummaryCard + MonthSummaryCard + DailyFlowChart
//

import SwiftUI
import Charts

// MARK: - Year Summary Card

struct YearSummaryCard: View {
    let year: Int
    let income: Decimal
    let expense: Decimal
    let availableYears: [Int]
    let onYearChange: (Int) -> Void

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
                    amount: income.compactTRY,
                    color: BrandColor.income
                )
                Divider()
                    .frame(width: 1)
                    .background(BrandColor.borderSubtle)
                    .padding(.vertical, Spacing.xs)
                statColumn(
                    arrow: "arrow.down",
                    label: "GİDER (YIL)",
                    amount: expense.compactTRY,
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
                Button("\(y)") { onYearChange(y) }
            }
        } label: {
            HStack(spacing: 4) {
                Text("\(year)")
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

    private func statColumn(arrow: String, label: String, amount: String, color: Color) -> some View {
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

    private var net: Decimal { income - expense }
    private var isNegativeNet: Bool { net < 0 }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header
            HStack {
                Text("AKTİF AY")
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
                    .tracking(1.2)
                Spacer()
                monthPicker
            }

            // Income / Expense columns
            HStack(spacing: 0) {
                amountColumn(
                    arrow: "arrow.up.right",
                    label: "Gelir",
                    amount: income.fullTRY,
                    color: BrandColor.income
                )
                amountColumn(
                    arrow: "arrow.down.right",
                    label: "Gider",
                    amount: expense.fullTRY,
                    color: BrandColor.expense
                )
            }

            // Net
            HStack(spacing: 4) {
                Image(systemName: isNegativeNet ? "arrow.down" : "arrow.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isNegativeNet ? BrandColor.expense : BrandColor.income)
                Text("Net \(isNegativeNet ? "−" : "+")\((abs(net)).fullTRY) (\(turkishMonthShort(month)))")
                    .font(.brand(.footnote))
                    .foregroundStyle(isNegativeNet ? BrandColor.expense : BrandColor.income)
                Spacer()
            }

            // Chart
            VStack(spacing: Spacing.xs) {
                HStack {
                    Text("GÜNLÜK AKIŞ · \(turkishMonthShort(month).uppercased())")
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

    private var monthPicker: some View {
        Menu {
            ForEach(1...12, id: \.self) { m in
                Button("\(turkishMonthShort(m)) \(year)") { onMonthChange(m) }
            }
        } label: {
            HStack(spacing: 4) {
                Text("\(turkishMonthShort(month)) \(year)")
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

    private func amountColumn(arrow: String, label: String, amount: String, color: Color) -> some View {
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

    private func legendDot(color: Color, label: String) -> some View {
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
                    x: .value("Gün", point.day),
                    y: .value("Tutar", point.amount)
                )
                .foregroundStyle(by: .value("Tür", point.kind == .income ? "Gelir" : "Gider"))
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
            .chartForegroundStyleScale([
                "Gelir": BrandColor.income,
                "Gider": BrandColor.expense
            ])
            .chartLegend(.hidden)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 72)
        }
    }
}

// MARK: - AI Insight Card

struct AIInsightCard: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Purple left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(BrandColor.primary)
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
                    Text("UYARI")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(BrandColor.expense)
                        .clipShape(Capsule())
                }
                Text("Bu ay harcamalarınız geçen aya göre %23 artış gösterdi. Alışveriş ve yemek kategorilerini gözden geçirmenizi öneririm.")
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.lg)
        .glassCard(cornerRadius: Spacing.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                .strokeBorder(BrandColor.primary.opacity(0.25), lineWidth: 1)
        )
    }
}
