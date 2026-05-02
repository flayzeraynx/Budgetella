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
    @Environment(\.hideAmounts) private var hideAmounts

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {

                        // Segment picker
                        segmentPicker
                            .padding(.horizontal, 20)

                        switch vm.selectedSegment {
                        case .genel:  genelContent
                        case .butce:  premiumSection(title: "Bütçe Takibi", icon: "chart.bar.doc.horizontal")
                        case .tahmin: premiumSection(title: "Ay Sonu Tahmini", icon: "wand.and.sparkles")
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.top, Spacing.sm)
                }
            }
            .navigationTitle("İstatistik")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    monthPicker
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .preferredColorScheme(.dark)
            .onAppear {
                guard !didAutoSelect else { return }
                vm.autoSelectPeriod(from: transactions)
                didAutoSelect = true
            }
        }
    }

    // MARK: - Segment picker

    private var segmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(StatsViewModel.Segment.allCases, id: \.self) { seg in
                Button {
                    withAnimation(.spring(response: 0.3)) { vm.selectedSegment = seg }
                } label: {
                    Text(seg.rawValue)
                        .font(.brand(.subheadline))
                        .foregroundStyle(vm.selectedSegment == seg ? .white : BrandColor.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(vm.selectedSegment == seg ? BrandColor.primary : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(BrandColor.surface.opacity(0.4))
        .clipShape(Capsule())
    }

    // MARK: - Genel content

    private var genelContent: some View {
        let breakdown = vm.categoryBreakdown(from: transactions, categories: categories)
        let total     = vm.totalExpense(from: transactions)
        let change    = vm.percentChange(from: transactions)

        return VStack(spacing: Spacing.lg) {
            // Donut chart card
            donutCard(total: total, change: change, breakdown: breakdown)
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

    private func donutCard(total: Decimal, change: Double?, breakdown: [CategoryStat]) -> some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                if breakdown.isEmpty {
                    Circle()
                        .stroke(BrandColor.borderSubtle, lineWidth: 24)
                        .frame(width: 160, height: 160)
                } else {
                    Chart(breakdown) { stat in
                        SectorMark(
                            angle: .value("Tutar", (stat.amount as NSDecimalNumber).doubleValue),
                            innerRadius: .ratio(0.62),
                            angularInset: 2
                        )
                        .cornerRadius(4)
                        .foregroundStyle(Color(hex: stat.category.colorHex))
                    }
                    .frame(width: 160, height: 160)
                }

                VStack(spacing: 2) {
                    Text("TOPLAM GİDER")
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.textTertiary)
                        .tracking(0.8)
                    Text(hideAmounts ? "••••" : total.fullTRY)
                        .font(.brand(.title))
                        .foregroundStyle(BrandColor.textPrimary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    if let pct = change {
                        HStack(spacing: 2) {
                            Image(systemName: pct >= 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 9, weight: .bold))
                            Text(String(format: "%%%.1f geçen aya göre", abs(pct)))
                                .font(.brand(.caption))
                        }
                        .foregroundStyle(pct >= 0 ? BrandColor.expense : BrandColor.income)
                    }
                }
                .frame(width: 110)
                .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.xl)
        .glassCard(cornerRadius: Spacing.radiusMedium)
    }

    private func categoryList(breakdown: [CategoryStat], total: Decimal) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Kategori dağılımı")
                .font(.brand(.subheadline))
                .foregroundStyle(BrandColor.textPrimary)
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
            Text(stat.category.name)
                .font(.brand(.subheadline))
                .foregroundStyle(BrandColor.textPrimary)
                .frame(maxWidth: 100, alignment: .leading)

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
                        Button(turkishMonthFull(m)) {
                            vm.selectedYear  = yr
                            vm.selectedMonth = m
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(turkishMonthShort(vm.selectedMonth))
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
