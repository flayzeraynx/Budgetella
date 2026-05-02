//
//  DashboardView.swift
//  Budgetella
//

import SwiftUI
import SwiftData

struct DashboardView: View {

    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    @Query(sort: \Category.sortOrder)
    private var categories: [Category]

    @AppStorage("displayName") private var displayName = "Ozzy"
    @AppStorage("userPhotoURL") private var userPhotoURL = ""
    @State private var vm = DashboardViewModel()
    @State private var showSettings = false
    @Environment(\.hideAmounts) private var hideAmounts

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Hero gradient section
                heroSection
                    .padding(.bottom, Spacing.lg)

                // ── Combined year + month card
                DashboardMainCard(
                    year: vm.selectedYear,
                    month: vm.selectedMonth,
                    yearIncome: vm.yearlyIncome(from: transactions),
                    yearExpense: vm.yearlyExpense(from: transactions),
                    monthIncome: vm.monthlyIncome(from: transactions),
                    monthExpense: vm.monthlyExpense(from: transactions),
                    dailyData: vm.dailyFlowData(from: transactions),
                    availableYears: vm.availableYears,
                    onYearChange: { vm.selectedYear = $0 },
                    onMonthChange: { vm.selectedMonth = $0 }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, Spacing.lg)

                // ── AI Insight
                AIInsightCard()
                    .padding(.horizontal, 20)
                    .padding(.bottom, Spacing.lg)

                // ── Top categories
                if !topExpenseCategories.isEmpty {
                    categorySection
                        .padding(.horizontal, 20)
                }

                Spacer(minLength: 100)
            }
        }
        .background(BrandColor.background.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Hero section

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [BrandColor.primary.opacity(0.28), BrandColor.primary.opacity(0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)

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
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Avatar

    private var avatarBadge: some View {
        Button { showSettings = true } label: {
            Group {
                if let url = URL(string: userPhotoURL), !userPhotoURL.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        default:
                            initialsCircle
                        }
                    }
                } else {
                    initialsCircle
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var initialsCircle: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [BrandColor.primary, BrandColor.primaryLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
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
            Calendar.current.component(.year,  from: $0.date) == vm.selectedYear &&
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
            Text(hideAmounts ? "••••" : amount.fullTRY)
                .font(.brand(.subheadline))
                .foregroundStyle(BrandColor.expense)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .glassCard(cornerRadius: Spacing.radiusSmall)
    }
}
