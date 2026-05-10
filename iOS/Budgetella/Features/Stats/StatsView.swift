//
//  StatsView.swift
//  Budgetella
//
//  05 · İstatistik — donut chart + kategori dağılımı + Bütçe/Tahmin premium
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {

    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @State private var vm = StatsViewModel()
    @State private var didAutoSelect = false
    @State private var showingIncome = true
    @Environment(\.hideAmounts) private var hideAmounts

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        genelContent
                        Spacer(minLength: 100)
                    }
                    .padding(.top, Spacing.sm)
                }
            }
            .navigationTitle("İstatistik")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    monthPicker
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .onAppear {
                guard !didAutoSelect else { return }
                vm.autoSelectPeriod(from: transactions)
                didAutoSelect = true
            }
        }
    }

    // MARK: - Segment picker

    private var segmentPicker: some View {
        HStack(spacing: 2) {
            ForEach(StatsViewModel.Segment.allCases, id: \.self) { seg in
                Button {
                    withAnimation(.spring(response: 0.3)) { vm.selectedSegment = seg }
                } label: {
                    Text(LocalizedStringKey(seg.rawValue))
                        .font(.brand(.footnote))
                        .foregroundStyle(vm.selectedSegment == seg ? .white : BrandColor.textTertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(vm.selectedSegment == seg ? BrandColor.primary : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(BrandColor.surface.opacity(0.5))
        .clipShape(Capsule())
    }

    // MARK: - Genel content

    private var genelContent: some View {
        let expenseBreakdown = vm.categoryBreakdown(from: transactions, categories: categories)
        let incomeBreakdown  = vm.incomBreakdown(from: transactions, categories: categories)
        let breakdown = showingIncome ? incomeBreakdown : expenseBreakdown
        let total     = showingIncome ? vm.totalIncome(from: transactions) : vm.totalExpense(from: transactions)
        let change    = showingIncome ? nil : vm.percentChange(from: transactions)

        return VStack(spacing: Spacing.lg) {
            // Income / Expense toggle
            incomeExpenseToggle
                .padding(.horizontal, 20)

            // Donut chart card
            donutCard(total: total, change: change, breakdown: breakdown, isIncome: showingIncome)
                .padding(.horizontal, 20)

            // Budgi AI insight — above categories
            AIInsightCard()
                .padding(.horizontal, 20)

            // Category list
            if !breakdown.isEmpty {
                categoryList(breakdown: breakdown, total: total)
                    .padding(.horizontal, 20)
            } else {
                emptyStatsState
                    .padding(.horizontal, 20)
            }
        }
    }

    private var incomeExpenseToggle: some View {
        HStack(spacing: 4) {
            ForEach([(false, "Gider" as LocalizedStringKey, BrandColor.expense), (true, "Gelir" as LocalizedStringKey, BrandColor.income)], id: \.0) { isIncome, label, color in
                Button {
                    withAnimation(.spring(response: 0.3)) { showingIncome = isIncome }
                } label: {
                    Text(label)
                        .font(.brand(.footnote))
                        .foregroundStyle(
                            showingIncome == isIncome
                                ? (isIncome ? Color.black.opacity(0.75) : .white)
                                : BrandColor.textTertiary
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(showingIncome == isIncome ? color : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(BrandColor.surface.opacity(0.5))
        .clipShape(Capsule())
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func donutCard(total: Decimal, change: Double?, breakdown: [CategoryStat], isIncome: Bool) -> some View {
        HStack(alignment: .center, spacing: Spacing.lg) {
            // Left: donut only, no labels inside
            ZStack {
                if breakdown.isEmpty {
                    Circle()
                        .stroke(BrandColor.borderSubtle, lineWidth: 20)
                        .frame(width: 110, height: 110)
                } else {
                    Chart(breakdown) { stat in
                        SectorMark(
                            angle: .value("Tutar", (stat.amount as NSDecimalNumber).doubleValue),
                            innerRadius: .ratio(0.58),
                            angularInset: 2
                        )
                        .cornerRadius(4)
                        .foregroundStyle(Color(hex: stat.category.colorHex))
                    }
                    .frame(width: 110, height: 110)
                    // Donut redraws on every income/expense toggle; Metal it.
                    .drawingGroup()
                }
            }

            // Right: labels with room to breathe
            VStack(alignment: .leading, spacing: 6) {
                Text(isIncome ? "TOPLAM GELİR" : "TOPLAM GİDER")
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
                    .tracking(0.8)

                Text(hideAmounts ? "••••" : total.fullTRY)
                    .font(.brand(.displayHero))
                    .foregroundStyle(isIncome ? BrandColor.income : BrandColor.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                if let pct = change {
                    HStack(spacing: 3) {
                        Image(systemName: pct >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                        Text(String(format: String(localized: "%.1f%% geçen aya göre"), abs(pct)))
                            .font(.brand(.footnote))
                    }
                    .foregroundStyle(pct >= 0 ? BrandColor.expense : BrandColor.income)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.lg)
        .glassCard(cornerRadius: Spacing.radiusMedium)
    }

    private func categoryList(breakdown: [CategoryStat], total: Decimal) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("KATEGORİ DAĞILIMI")
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            VStack(spacing: Spacing.xs) {
                ForEach(breakdown) { stat in
                    categoryRow(stat: stat)
                }
            }
        }
    }

    private func categoryRow(stat: CategoryStat) -> some View {
        let color = Color(hex: stat.category.colorHex)
        return HStack(spacing: Spacing.sm) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(stat.category.localizedDisplayName)
                .font(.brand(.subheadline))
                .foregroundStyle(BrandColor.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 110, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(BrandColor.borderSubtle).frame(height: 4)
                    Capsule().fill(color)
                        .frame(width: geo.size.width * stat.percentage, height: 4)
                }
            }
            .frame(height: 4)

            Text(hideAmounts ? "••••" : stat.amount.fullTRY)
                .font(.brand(.footnote))
                .foregroundStyle(BrandColor.textSecondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .glassCard(cornerRadius: Spacing.radiusSmall)
    }

    private var emptyStatsState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(BrandColor.primary)
                .symbolRenderingMode(.hierarchical)
            Text("Henüz analiz edecek bir şey yok")
                .font(.brand(.title))
                .foregroundStyle(BrandColor.textPrimary)
                .multilineTextAlignment(.center)
            Text("Birkaç işlem ekledikten sonra Budgi senin için trend, tahmin ve insight kartları üretmeye başlar.")
                .font(.brand(.body))
                .foregroundStyle(BrandColor.textTertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                Text("İPUCU")
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.primary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background(BrandColor.primary.opacity(0.15))
                    .clipShape(Capsule())
                Text("En az 5 işlem ile haftalık özet aktifleşir")
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textSecondary)
            }
            .padding(Spacing.md)
            .glassCard(cornerRadius: Spacing.radiusSmall)
        }
        .padding(.top, Spacing.xxl)
    }

    // MARK: - Premium section

    private func premiumSection(title: String, icon: String) -> some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(BrandColor.primary)
                .symbolRenderingMode(.hierarchical)
                .padding(.top, Spacing.xxxl)
            Text(title)
                .font(.brand(.title))
                .foregroundStyle(BrandColor.textPrimary)
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text("Premium özellik")
                    .font(.brand(.footnote))
            }
            .foregroundStyle(BrandColor.primary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(BrandColor.primary.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // MARK: - Month picker

    private var monthPicker: some View {
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: .now)
        let currentMonth = cal.component(.month, from: .now)

        return Menu {
            ForEach(vm.availableYears, id: \.self) { yr in
                Section("\(yr)") {
                    let maxMonth = yr == currentYear ? currentMonth : 12
                    ForEach(Array(stride(from: maxMonth, through: 1, by: -1)), id: \.self) { m in
                        Button(monthFull(m)) {
                            vm.selectedYear  = yr
                            vm.selectedMonth = m
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(monthFull(vm.selectedMonth))
                    .font(.brand(.subheadline))
                    .foregroundStyle(BrandColor.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 5)
            .background(BrandColor.background3)
            .clipShape(Capsule())
        }
    }
}
