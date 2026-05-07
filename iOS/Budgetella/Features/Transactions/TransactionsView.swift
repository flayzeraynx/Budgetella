//
//  TransactionsView.swift
//  Budgetella
//

import SwiftUI
import SwiftData

struct TransactionsView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(FirestoreService.self) private var firestoreService
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @AppStorage("currentUserId") private var currentUserId = ""
    @State private var vm = TransactionsViewModel()

    private var myTransactions: [Transaction] {
        transactions.filter { $0.userId == currentUserId }
    }
    private var myCategories: [Category] {
        categories.filter { $0.userId == currentUserId }
    }
    @State private var showFilter = false
    @State private var editingTransaction: Transaction?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, Spacing.xs)

                    // Filter chips
                    filterChips
                        .padding(.bottom, Spacing.xs)

                    Divider().background(BrandColor.borderSubtle)

                    // Transaction list
                    let yearGroups = vm.groupedHierarchical(myTransactions)
                    if firestoreService.isSyncing {
                        syncingPlaceholder
                    } else if yearGroups.isEmpty {
                        emptyState
                    } else {
                        transactionList(yearGroups: yearGroups)
                    }
                }
            }
            .navigationTitle("İşlemler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    typeFilterPicker
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilter = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(BrandColor.background3)
                                .frame(width: 32, height: 32)
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(
                                    vm.categoryFilter != nil
                                    ? BrandColor.primary
                                    : BrandColor.textSecondary
                                )
                        }
                    }
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .sheet(isPresented: $showFilter) {
                CategoryFilterSheet(vm: vm, categories: myCategories)
            }
            .sheet(item: $editingTransaction) { tx in
                EditTransactionSheet(transaction: tx, categories: myCategories)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(BrandColor.textTertiary)
            TextField("İşlem ara...", text: $vm.searchText)
                .font(.brand(.body))
                .foregroundStyle(BrandColor.textPrimary)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit { isSearchFocused = false }
            if !vm.searchText.isEmpty || isSearchFocused {
                Button {
                    vm.searchText = ""
                    isSearchFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(BrandColor.textTertiary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 10)
        .background(BrandColor.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusFull))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusFull)
                .strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Type filter (toolbar principal)

    private var typeFilterPicker: some View {
        HStack(spacing: 2) {
            ForEach(
                [(id: 0, label: LocalizedStringKey("Tümü"),  type: Optional<TransactionType>.none),
                 (id: 1, label: LocalizedStringKey("Gelir"), type: Optional<TransactionType>.some(.income)),
                 (id: 2, label: LocalizedStringKey("Gider"), type: Optional<TransactionType>.some(.expense))],
                id: \.id
            ) { item in
                let isSelected = vm.typeFilter == item.type
                let activeColor: Color = {
                    switch item.type {
                    case .none:               return BrandColor.primary
                    case .some(.income):      return BrandColor.income
                    case .some(.expense):     return BrandColor.expense
                    }
                }()
                let activeTextColor: Color = item.type == .some(.income)
                    ? Color.black.opacity(0.75)
                    : .white

                Button {
                    withAnimation(.spring(response: 0.28)) { vm.typeFilter = item.type }
                } label: {
                    Text(item.label)
                        .font(.brand(.footnote))
                        .foregroundStyle(isSelected ? activeTextColor : BrandColor.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isSelected ? activeColor : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(BrandColor.surface.opacity(0.5))
        .clipShape(Capsule())
    }

    // MARK: - Category filter chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(myCategories) { cat in
                    let isActive = vm.categoryFilter == cat.id
                    filterChip(
                        label: cat.localizedDisplayName,
                        dotColor: Color(hex: cat.colorHex),
                        isActive: isActive
                    ) {
                        withAnimation(.spring(response: 0.28)) {
                            vm.categoryFilter = isActive ? nil : cat.id
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, Spacing.xs)
        }
    }

    private func filterChip(
        label: String,
        dotColor: Color? = nil,
        isActive: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if let dot = dotColor {
                    Circle().fill(dot).frame(width: 6, height: 6)
                }
                Text(label)
                    .font(.brand(.footnote))
                    .foregroundStyle(isActive ? .white : BrandColor.textSecondary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(isActive ? BrandColor.primary : BrandColor.surface.opacity(0.5))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isActive ? Color.clear : BrandColor.borderSubtle,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Transaction list

    private func transactionList(yearGroups: [TransactionYearGroup]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(yearGroups) { yearGroup in
                    yearHeader(yearGroup.year)

                    ForEach(yearGroup.months) { monthGroup in
                        monthHeader(monthGroup.month)

                        ForEach(monthGroup.days) { dayGroup in
                            dayHeader(dayGroup.title)

                            VStack(spacing: 0) {
                                ForEach(dayGroup.transactions) { tx in
                                    TransactionRow(
                                        transaction: tx,
                                        onDelete: {
                                            let txId = tx.id
                                            let txUserId = tx.userId
                                            modelContext.delete(tx)
                                            Task {
                                                try? await FirestoreService.shared.deleteTransaction(id: txId, userId: txUserId)
                                            }
                                        },
                                        onTap: { editingTransaction = tx }
                                    )

                                    if tx.id != dayGroup.transactions.last?.id {
                                        Divider()
                                            .background(BrandColor.borderSubtle)
                                            .padding(.leading, 68)
                                    }
                                }
                            }
                            .background(BrandColor.surface.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                                    .strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                            .padding(.bottom, Spacing.sm)
                        }
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.top, Spacing.sm)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func yearHeader(_ year: Int) -> some View {
        Text(String(year))
            .font(.brand(.title))
            .foregroundStyle(BrandColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, Spacing.lg)
            .padding(.bottom, 2)
    }

    private func monthHeader(_ month: Int) -> some View {
        Text(monthFull(month))
            .font(.brand(.headline))
            .foregroundStyle(BrandColor.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xs)
    }

    private func dayHeader(_ title: String) -> some View {
        Text(title)
            .font(.brand(.caption))
            .foregroundStyle(BrandColor.textTertiary)
            .tracking(0.6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, Spacing.sm)
            .padding(.bottom, 4)
    }

    // MARK: - Syncing placeholder

    private var syncingPlaceholder: some View {
        VStack(spacing: Spacing.xs) {
            // Month header skeleton
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(BrandColor.surface)
                .frame(width: 80, height: 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xs)

            // Row group — glass card
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { i in
                    HStack(spacing: Spacing.md) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(BrandColor.surface)
                            .frame(width: 40, height: 40)
                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(BrandColor.surface)
                                .frame(width: i == 1 ? 110 : 88, height: 13)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(BrandColor.surface.opacity(0.7))
                                .frame(width: i == 1 ? 60 : 76, height: 11)
                        }
                        Spacer()
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(BrandColor.surface)
                            .frame(width: i == 0 ? 72 : 56, height: 13)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, 12)

                    if i < 2 {
                        Divider()
                            .background(BrandColor.borderSubtle)
                            .padding(.leading, 68)
                    }
                }
            }
            .background(BrandColor.surface.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                    .strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, Spacing.sm)

            // Day header skeleton
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(BrandColor.surface.opacity(0.6))
                .frame(width: 56, height: 11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, Spacing.sm)
                .padding(.bottom, 4)

            // Second row group
            VStack(spacing: 0) {
                ForEach(0..<2, id: \.self) { i in
                    HStack(spacing: Spacing.md) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(BrandColor.surface)
                            .frame(width: 40, height: 40)
                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(BrandColor.surface)
                                .frame(width: i == 0 ? 96 : 120, height: 13)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(BrandColor.surface.opacity(0.7))
                                .frame(width: i == 0 ? 68 : 50, height: 11)
                        }
                        Spacer()
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(BrandColor.surface)
                            .frame(width: i == 0 ? 64 : 80, height: 13)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, 12)

                    if i < 1 {
                        Divider()
                            .background(BrandColor.borderSubtle)
                            .padding(.leading, 68)
                    }
                }
            }
            .background(BrandColor.surface.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                    .strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
            )
            .padding(.horizontal, 20)

            Spacer()
        }
        .shimmer()
        .padding(.top, Spacing.sm)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(BrandColor.primary)
                .symbolRenderingMode(.hierarchical)
            Text(vm.searchText.isEmpty && vm.typeFilter == nil && vm.categoryFilter == nil
                 ? "Henüz işlem yok"
                 : "Sonuç bulunamadı")
                .font(.brand(.title))
                .foregroundStyle(BrandColor.textPrimary)
                .multilineTextAlignment(.center)
            Text(vm.searchText.isEmpty && vm.typeFilter == nil && vm.categoryFilter == nil
                 ? "+ butonuyla ilk işlemini ekle"
                 : "Farklı filtreler dene")
                .font(.brand(.body))
                .foregroundStyle(BrandColor.textTertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Category Filter Sheet

private struct CategoryFilterSheet: View {
    @Bindable var vm: TransactionsViewModel
    let categories: [Category]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                List {
                    Section("Kategori") {
                        filterRow(label: "Tüm Kategoriler", isSelected: vm.categoryFilter == nil) {
                            vm.categoryFilter = nil
                        }
                        ForEach(categories) { cat in
                            filterRow(
                                label: cat.localizedDisplayName,
                                dotColor: Color(hex: cat.colorHex),
                                isSelected: vm.categoryFilter == cat.id
                            ) {
                                vm.categoryFilter = vm.categoryFilter == cat.id ? nil : cat.id
                            }
                        }
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.5))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Filtrele")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tamam") { dismiss() }
                        .foregroundStyle(BrandColor.primary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sıfırla") {
                        vm.categoryFilter = nil
                        vm.typeFilter = nil
                    }
                    .foregroundStyle(BrandColor.textTertiary)
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func filterRow(
        label: String,
        dotColor: Color? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let dot = dotColor {
                    Circle().fill(dot).frame(width: 10, height: 10)
                } else {
                    Circle().fill(BrandColor.borderMedium).frame(width: 10, height: 10)
                }
                Text(label)
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BrandColor.primary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
