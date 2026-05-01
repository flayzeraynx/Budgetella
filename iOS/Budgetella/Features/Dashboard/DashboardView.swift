//
//  DashboardView.swift
//  Budgetella
//
//  03 · Glass premium dashboard — yıllık özet + aylık kart + AI insight + kategoriler
//

import SwiftUI
import SwiftData

struct DashboardView: View {

    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    @Query(sort: \Category.sortOrder)
    private var categories: [Category]

    @AppStorage("displayName") private var displayName = "Ozzy"
    @State private var vm = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {

                // ── Header
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                // ── Year card
                YearSummaryCard(
                    year: vm.selectedYear,
                    income: vm.yearlyIncome(from: transactions),
                    expense: vm.yearlyExpense(from: transactions),
                    availableYears: vm.availableYears,
                    onYearChange: { vm.selectedYear = $0 }
                )
                .padding(.horizontal, 20)

                // ── Month card
                MonthSummaryCard(
                    year: vm.selectedYear,
                    month: vm.selectedMonth,
                    income: vm.monthlyIncome(from: transactions),
                    expense: vm.monthlyExpense(from: transactions),
                    dailyData: vm.dailyFlowData(from: transactions),
                    onMonthChange: { vm.selectedMonth = $0 }
                )
                .padding(.horizontal, 20)

                // ── AI Insight
                AIInsightCard()
                    .padding(.horizontal, 20)

                // ── Top categories
                if !topExpenseCategories.isEmpty {
                    categorySection
                        .padding(.horizontal, 20)
                }

                // Tab bar clearance
                Spacer(minLength: 100)
            }
            .padding(.top, 8)
        }
        .background(BrandColor.background.ignoresSafeArea())
        .scrollIndicators(.hidden)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.greeting)
                    .font(.brand(.subheadline))
                    .foregroundStyle(BrandColor.textSecondary)
                HStack(spacing: 6) {
                    Text(displayName)
                        .font(.brand(.title))
                        .foregroundStyle(BrandColor.textPrimary)
                    Text("👋")
                        .font(.system(size: 22))
                }
            }
            Spacer()
            avatarBadge
        }
    }

    private var avatarBadge: some View {
        ZStack {
            Circle()
                .fill(Color.orange)
                .frame(width: 40, height: 40)
            Text(String(displayName.prefix(1)).uppercased())
                .font(.brand(.headline))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Category section

    private var topExpenseCategories: [(Category, Decimal)] {
        let monthly = transactions.filter {
            $0.type == .expense &&
            Calendar.current.component(.year, from: $0.date) == vm.selectedYear &&
            Calendar.current.component(.month, from: $0.date) == vm.selectedMonth
        }
        var totals: [UUID: Decimal] = [:]
        for tx in monthly {
            guard let cat = tx.category else { continue }
            totals[cat.id, default: 0] += tx.amount
        }
        return categories
            .filter { totals[$0.id] != nil }
            .map { ($0, totals[$0.id]!) }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0 }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("KATEGORİLER")
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            VStack(spacing: Spacing.xs) {
                ForEach(topExpenseCategories, id: \.0.id) { cat, amount in
                    categoryRow(cat: cat, amount: amount)
                }
            }
        }
    }

    private func categoryRow(cat: Category, amount: Decimal) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color(hex: cat.colorHex).opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: cat.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: cat.colorHex))
            }
            Text(cat.name)
                .font(.brand(.subheadline))
                .foregroundStyle(BrandColor.textPrimary)
            Spacer()
            Text(amount.fullTRY)
                .font(.brand(.subheadline))
                .foregroundStyle(BrandColor.expense)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .glassCard(cornerRadius: Spacing.radiusSmall)
    }
}
