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

    @AppStorage("displayName") private var displayName = ""
    @AppStorage("userPhotoURL") private var userPhotoURL = ""
    @AppStorage("currentUserId") private var currentUserId = ""
    @State private var vm = DashboardViewModel()
    @State private var showSettings = false
    @State private var showNotifications = false
    @Environment(\.hideAmounts) private var hideAmounts
    @Environment(FirestoreService.self) private var firestoreService

    // Okunmamış bildirim sayısı — bell badge için
    @Query private var allNotifications: [NotificationRecord]
    private var unreadCount: Int {
        allNotifications.filter { !$0.isRead && ($0.userId == currentUserId || $0.userId == "local") }.count
    }

    private var myTransactions: [Transaction] {
        transactions.filter { $0.userId == currentUserId }
    }
    private var myCategories: [Category] {
        categories.filter { $0.userId == currentUserId }
    }

    var body: some View {
        ZStack(alignment: .top) {
            BrandColor.background.ignoresSafeArea()

            // Fixed gradient — always covers status bar, does not scroll
            LinearGradient(
                colors: [BrandColor.primary.opacity(0.28), BrandColor.primary.opacity(0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Hero content (no gradient wrapper)
                    heroContent
                        .padding(.bottom, Spacing.lg)

                    // ── Combined year + month card
                    DashboardMainCard(
                        year: vm.selectedYear,
                        month: vm.selectedMonth,
                        yearIncome: vm.yearlyIncome(from: myTransactions),
                        yearExpense: vm.yearlyExpense(from: myTransactions),
                        monthIncome: vm.monthlyIncome(from: myTransactions),
                        monthExpense: vm.monthlyExpense(from: myTransactions),
                        dailyData: vm.dailyFlowData(from: myTransactions),
                        availableYears: vm.availableYears(from: myTransactions),
                        onYearChange: { vm.selectedYear = $0 },
                        onMonthChange: { vm.selectedMonth = $0 }
                    )
                    .redacted(reason: firestoreService.isSyncing ? .placeholder : [])
                    .shimmer(active: firestoreService.isSyncing)
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
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsInboxView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appShowNotifications)) { _ in
            showNotifications = true
        }
    }

    // MARK: - Hero content

    private var heroContent: some View {
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
            HStack(spacing: Spacing.sm) {
                bellButton
                avatarBadge
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, Spacing.xl)
    }

    // MARK: - Bell button

    private var bellButton: some View {
        Button { showNotifications = true } label: {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(BrandColor.surface.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle().strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
                    }

                Image(systemName: unreadCount > 0 ? "bell.fill" : "bell")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(unreadCount > 0 ? BrandColor.primary : BrandColor.textSecondary)
                    .frame(width: 40, height: 40)

                // Badge
                if unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(BrandColor.expense)
                            .frame(width: 18, height: 18)
                        Text(unreadCount > 9 ? "9+" : "\(unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 5, y: -5)
                }
            }
        }
        .buttonStyle(.plain)
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
        let monthly = myTransactions.filter {
            $0.type == .expense &&
            Calendar.current.component(.year,  from: $0.date) == vm.selectedYear &&
            Calendar.current.component(.month, from: $0.date) == vm.selectedMonth
        }
        var totals: [UUID: Decimal] = [:]
        for tx in monthly {
            guard let cat = tx.category else { continue }
            totals[cat.id, default: 0] += tx.amount
        }
        return myCategories
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
            Text(cat.localizedDisplayName)
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
