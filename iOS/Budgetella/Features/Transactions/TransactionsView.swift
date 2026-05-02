//
//  TransactionsView.swift
//  Budgetella
//

import SwiftUI
import SwiftData

struct TransactionsView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @State private var vm = TransactionsViewModel()
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
                    let sections = vm.grouped(transactions)
                    if sections.isEmpty {
                        emptyState
                    } else {
                        transactionList(sections: sections)
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
                CategoryFilterSheet(vm: vm, categories: categories)
            }
            .sheet(item: $editingTransaction) { tx in
                EditTransactionSheet(transaction: tx, categories: categories)
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
                [(label: "Tümü", type: nil as TransactionType?),
                 (label: "Gelir", type: .income),
                 (label: "Gider", type: .expense)],
                id: \.label
            ) { item in
                Button {
                    withAnimation(.spring(response: 0.28)) { vm.typeFilter = item.type }
                } label: {
                    Text(item.label)
                        .font(.brand(.footnote))
                        .foregroundStyle(vm.typeFilter == item.type ? .white : BrandColor.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(vm.typeFilter == item.type ? BrandColor.primary : Color.clear)
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
                ForEach(categories) { cat in
                    let isActive = vm.categoryFilter == cat.id
                    filterChip(
                        label: cat.name,
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

    private func transactionList(sections: [TransactionSection]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(sections) { section in
                    Section {
                        VStack(spacing: 0) {
                            ForEach(section.transactions) { tx in
                                TransactionRow(transaction: tx, onDelete: {
                                    let txId = tx.id
                                    let txUserId = tx.userId
                                    modelContext.delete(tx)
                                    Task {
                                        try? await FirestoreService.shared.deleteTransaction(id: txId, userId: txUserId)
                                    }
                                })
                                .onTapGesture { editingTransaction = tx }

                                if tx.id != section.transactions.last?.id {
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
                    } header: {
                        sectionHeader(section)
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.top, Spacing.sm)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func sectionHeader(_ section: TransactionSection) -> some View {
        HStack {
            Text(section.title)
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
                .tracking(0.8)
            Spacer()
            let isPositive = section.netAmount >= 0
            Text((isPositive ? "+" : "") + section.netAmount.fullTRY)
                .font(.brand(.caption))
                .foregroundStyle(isPositive ? BrandColor.income : BrandColor.expense)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, Spacing.xs)
        .background(BrandColor.background)
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
                                label: cat.name,
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
