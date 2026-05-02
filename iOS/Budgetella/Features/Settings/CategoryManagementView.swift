//
//  CategoryManagementView.swift
//  Budgetella
//

import SwiftUI
import SwiftData

struct CategoryManagementView: View {

    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currentUserId") private var currentUserId = ""
    @State private var subscriptionService = SubscriptionService()
    @State private var showAddSheet = false
    @State private var editingCategory: Category?
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false
    @State private var categoryToDelete: Category?

    private var expenseCategories: [Category] { categories.filter { $0.type == .expense } }
    private var incomeCategories: [Category] { categories.filter { $0.type == .income } }

    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()

            List {
                if !subscriptionService.isPremium {
                    premiumBanner
                }

                if !expenseCategories.isEmpty {
                    categorySection(title: "GİDER", items: expenseCategories)
                }

                if !incomeCategories.isEmpty {
                    categorySection(title: "GELİR", items: incomeCategories)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Kategoriler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BrandColor.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if subscriptionService.isPremium {
                        showAddSheet = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BrandColor.primary)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddCategorySheet(userId: currentUserId)
        }
        .sheet(item: $editingCategory) { cat in
            EditCategorySheet(category: cat)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .brandAlert(
            title: "Kategoriyi Sil",
            message: "Bu kategori silinecek. İlişkili işlemlerin kategorisi kaldırılacak.",
            isPresented: $showDeleteConfirm,
            buttons: [
                .destructive("Sil") {
                    if let cat = categoryToDelete {
                        modelContext.delete(cat)
                    }
                },
                .cancel()
            ]
        )
        .task { await subscriptionService.setup(userId: currentUserId) }
    }

    // MARK: - Sections

    private var premiumBanner: some View {
        Section {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(BrandColor.primary.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(BrandColor.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Özel Kategoriler Premium")
                        .font(.brand(.subheadline).bold())
                        .foregroundStyle(BrandColor.primary)
                    Text("Kendi kategorilerini eklemek için Premium gerekli.")
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(BrandColor.textTertiary.opacity(0.5))
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture { showPaywall = true }
        }
        .listRowBackground(BrandColor.primary.opacity(0.06))
    }

    private func categorySection(title: String, items: [Category]) -> some View {
        Section(title) {
            ForEach(items) { cat in
                categoryRow(cat)
            }
        }
        .listRowBackground(BrandColor.surface.opacity(0.4))
    }

    // MARK: - Row

    private func categoryRow(_ cat: Category) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color(hex: cat.colorHex).opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: cat.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: cat.colorHex))
            }

            Text(cat.name)
                .font(.brand(.body))
                .foregroundStyle(BrandColor.textPrimary)

            Spacer()

            if cat.isDefault {
                Text("Varsayılan")
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(BrandColor.surface.opacity(0.6))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing) {
            if !cat.isDefault && subscriptionService.isPremium {
                Button(role: .destructive) {
                    categoryToDelete = cat
                    showDeleteConfirm = true
                } label: {
                    Label("Sil", systemImage: "trash")
                }

                Button {
                    editingCategory = cat
                } label: {
                    Label("Düzenle", systemImage: "pencil")
                }
                .tint(BrandColor.primary)
            }
        }
    }
}

// MARK: - Add Category Sheet

struct AddCategorySheet: View {

    let userId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedIcon = "tag"
    @State private var selectedColorHex = "#6E5BFF"

    private let iconOptions = [
        "tag", "cart", "fork.knife", "car", "house", "heart",
        "gamecontroller", "book", "airplane", "music.note",
        "dumbbell", "bag", "creditcard", "gift", "pawprint"
    ]

    private let colorOptions = [
        "#6E5BFF", "#FF6B6B", "#4CAF50", "#FF9800", "#2196F3",
        "#E91E63", "#9C27B0", "#00BCD4", "#8BC34A", "#FF5722"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {

                        // Preview
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: selectedColorHex).opacity(0.2))
                                    .frame(width: 52, height: 52)
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(Color(hex: selectedColorHex))
                            }
                            Text(name.isEmpty ? "Kategori Adı" : name)
                                .font(.brand(.headline))
                                .foregroundStyle(name.isEmpty ? BrandColor.textTertiary : BrandColor.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.md)
                        .glassCard(cornerRadius: 14)

                        // Name input
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("KATEGORİ ADI")
                                .font(.brand(.caption))
                                .foregroundStyle(BrandColor.textTertiary)
                                .tracking(1.2)

                            TextField("Örn. Kitap, Spor…", text: $name)
                                .font(.brand(.body))
                                .foregroundStyle(BrandColor.textPrimary)
                                .tint(BrandColor.primary)
                                .padding(Spacing.md)
                                .glassCard(cornerRadius: 12)
                        }

                        // Type picker
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("TÜR")
                                .font(.brand(.caption))
                                .foregroundStyle(BrandColor.textTertiary)
                                .tracking(1.2)

                            HStack(spacing: Spacing.sm) {
                                typeButton(.expense, label: "Gider", icon: "arrow.down.circle")
                                typeButton(.income, label: "Gelir", icon: "arrow.up.circle")
                            }
                        }

                        // Icon picker
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("İKON")
                                .font(.brand(.caption))
                                .foregroundStyle(BrandColor.textTertiary)
                                .tracking(1.2)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Spacing.sm) {
                                ForEach(iconOptions, id: \.self) { icon in
                                    Button {
                                        selectedIcon = icon
                                    } label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(selectedIcon == icon ? Color(hex: selectedColorHex).opacity(0.2) : BrandColor.surface.opacity(0.4))
                                            Image(systemName: icon)
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColorHex) : BrandColor.textSecondary)
                                        }
                                        .frame(height: 48)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .strokeBorder(
                                                    selectedIcon == icon ? Color(hex: selectedColorHex).opacity(0.5) : Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Color picker
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("RENK")
                                .font(.brand(.caption))
                                .foregroundStyle(BrandColor.textTertiary)
                                .tracking(1.2)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Spacing.sm) {
                                ForEach(colorOptions, id: \.self) { hex in
                                    Button {
                                        selectedColorHex = hex
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: hex))
                                                .frame(height: 40)
                                            if selectedColorHex == hex {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Yeni Kategori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                        .font(.brand(.body))
                        .foregroundStyle(BrandColor.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Ekle") {
                        addCategory()
                        dismiss()
                    }
                    .font(.brand(.subheadline).bold())
                    .foregroundStyle(name.isEmpty ? BrandColor.textTertiary : BrandColor.primary)
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func typeButton(_ type: TransactionType, label: String, icon: String) -> some View {
        let isSelected = selectedType == type
        return Button {
            selectedType = type
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                Text(label)
                    .font(.brand(.subheadline))
            }
            .foregroundStyle(isSelected ? .white : BrandColor.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? BrandColor.primary : BrandColor.surface.opacity(0.4))
            )
        }
        .buttonStyle(.plain)
    }

    private func addCategory() {
        let sortMax = (try? modelContext.fetch(FetchDescriptor<Category>()).map(\.sortOrder).max()) ?? 0
        let newCat = Category(
            userId: userId,
            name: name,
            type: selectedType,
            iconName: selectedIcon,
            colorHex: selectedColorHex,
            isDefault: false,
            sortOrder: sortMax + 1
        )
        modelContext.insert(newCat)
    }
}

// MARK: - Edit Category Sheet

struct EditCategorySheet: View {

    @Bindable var category: Category
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColorHex: String

    init(category: Category) {
        self.category = category
        _name = State(initialValue: category.name)
        _selectedIcon = State(initialValue: category.iconName)
        _selectedColorHex = State(initialValue: category.colorHex)
    }

    private let iconOptions = [
        "tag", "cart", "fork.knife", "car", "house", "heart",
        "gamecontroller", "book", "airplane", "music.note",
        "dumbbell", "bag", "creditcard", "gift", "pawprint"
    ]
    private let colorOptions = [
        "#6E5BFF", "#FF6B6B", "#4CAF50", "#FF9800", "#2196F3",
        "#E91E63", "#9C27B0", "#00BCD4", "#8BC34A", "#FF5722"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Name
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("KATEGORİ ADI")
                                .font(.brand(.caption))
                                .foregroundStyle(BrandColor.textTertiary)
                                .tracking(1.2)
                            TextField("Kategori adı", text: $name)
                                .font(.brand(.body))
                                .foregroundStyle(BrandColor.textPrimary)
                                .tint(BrandColor.primary)
                                .padding(Spacing.md)
                                .glassCard(cornerRadius: 12)
                        }

                        // Icon
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("İKON")
                                .font(.brand(.caption))
                                .foregroundStyle(BrandColor.textTertiary)
                                .tracking(1.2)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Spacing.sm) {
                                ForEach(iconOptions, id: \.self) { icon in
                                    Button { selectedIcon = icon } label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(selectedIcon == icon ? Color(hex: selectedColorHex).opacity(0.2) : BrandColor.surface.opacity(0.4))
                                            Image(systemName: icon)
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColorHex) : BrandColor.textSecondary)
                                        }
                                        .frame(height: 48)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Color
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("RENK")
                                .font(.brand(.caption))
                                .foregroundStyle(BrandColor.textTertiary)
                                .tracking(1.2)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Spacing.sm) {
                                ForEach(colorOptions, id: \.self) { hex in
                                    Button { selectedColorHex = hex } label: {
                                        ZStack {
                                            Circle().fill(Color(hex: hex)).frame(height: 40)
                                            if selectedColorHex == hex {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                        .font(.brand(.body))
                        .foregroundStyle(BrandColor.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kaydet") {
                        category.name = name
                        category.iconName = selectedIcon
                        category.colorHex = selectedColorHex
                        dismiss()
                    }
                    .font(.brand(.subheadline).bold())
                    .foregroundStyle(name.isEmpty ? BrandColor.textTertiary : BrandColor.primary)
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
