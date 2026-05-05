//
//  EditTransactionSheet.swift
//  Budgetella
//
//  Layout mirrors QuickEntry: tip toggle → kategoriler → tutar → açıklama → tarih → numpad → kaydet.
//  Tek fark: tarih satırı + sağ üstte silme butonu.
//

import SwiftUI
import SwiftData

struct EditTransactionSheet: View {

    @Bindable var transaction: Transaction
    let categories: [Category]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var showDeleteConfirm = false
    @State private var showCategoryPicker = false

    // Editable state
    @State private var note:             String           = ""
    @State private var rawInput:         String           = ""   // numpad input
    @State private var type:             TransactionType  = .expense
    @State private var selectedCategory: Category?        = nil
    @State private var date:             Date             = .now
    @State private var isRecurring:      Bool             = false
    @State private var isTyping:         Bool             = false

    @FocusState private var noteFocused: Bool

    // MARK: - Computed amount helpers

    private var wholePart: String { rawInput.components(separatedBy: ",").first ?? "0" }
    private var fracPart: String? {
        guard rawInput.contains(",") else { return nil }
        return rawInput.components(separatedBy: ",").last ?? ""
    }
    private var amountColor: Color { type == .expense ? BrandColor.expense : BrandColor.income }

    private func appendDigit(_ d: String) {
        let digits = rawInput.filter { $0.isNumber }
        guard digits.count < 10 else { return }
        if rawInput == "0" { rawInput = d; return }
        rawInput += d
    }
    private func appendDecimal() {
        if rawInput.isEmpty { rawInput = "0,"; return }
        if rawInput.contains(",") { return }
        rawInput += ","
    }
    private func backspace() {
        guard !rawInput.isEmpty else { return }
        rawInput.removeLast()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {

                            // 1 — Type toggle
                            typeToggle
                                .padding(.horizontal, 20)
                                .padding(.top, Spacing.md)

                            if !isTyping {
                                // 2 — Category chips
                                categoryChipsRow
                                    .padding(.top, Spacing.sm)

                                // 3 — Amount display
                                amountDisplay
                                    .padding(.horizontal, 20)
                                    .padding(.top, Spacing.md)
                            }

                            // 4 — Note field
                            noteField
                                .padding(.horizontal, 20)
                                .padding(.top, Spacing.sm)

                            if !isTyping {
                                // 5 — Date picker row
                                dateRow
                                    .padding(.horizontal, 20)
                                    .padding(.top, Spacing.xs)
                            }
                        }
                        .padding(.bottom, Spacing.sm)
                    }

                    if !isTyping {
                        // 6 — Numpad
                        NumpadGrid(
                            onDigit:   { appendDigit($0) },
                            onDecimal: { appendDecimal() },
                            onDelete:  { backspace() }
                        )
                        .padding(.horizontal, 12)
                        .padding(.top, Spacing.xs)

                        // 7 — Save button
                        Button { saveChanges() } label: {
                            Text("Kaydet")
                                .font(.brand(.headline))
                                .foregroundStyle(isValid ? .white : BrandColor.textTertiary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    isValid
                                    ? LinearGradient(colors: [BrandColor.primary, BrandColor.primaryLight],
                                                     startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [BrandColor.surface.opacity(0.5), BrandColor.surface.opacity(0.5)],
                                                     startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Capsule())
                                .shadow(color: isValid ? BrandColor.primary.opacity(0.4) : .clear, radius: 12, y: 4)
                        }
                        .disabled(!isValid)
                        .padding(.horizontal, 20)
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, 36)
                    }
                }
            }
            .animation(.spring(response: 0.3), value: isTyping)
            .navigationTitle("İşlemi Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Vazgeç") { dismiss() }
                        .foregroundStyle(BrandColor.textTertiary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showDeleteConfirm = true } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundStyle(BrandColor.expense)
                    }
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .sheet(isPresented: $showCategoryPicker) { editCategoryPicker }
            .brandAlert(
                title: "İşlemi Sil",
                message: "Bu işlem kalıcı olarak silinecek.",
                isPresented: $showDeleteConfirm,
                buttons: [
                    .destructive("Sil") {
                        let txId = transaction.id
                        let txUserId = transaction.userId
                        modelContext.delete(transaction)
                        Task { try? await FirestoreService.shared.deleteTransaction(id: txId, userId: txUserId) }
                        dismiss()
                    },
                    .cancel()
                ]
            )
        }
        .onAppear { loadFromTransaction() }
    }

    // MARK: - Type toggle

    private var typeToggle: some View {
        HStack(spacing: Spacing.sm) {
            typeButton(.expense, label: "Gider", icon: "arrow.down.right")
            typeButton(.income,  label: "Gelir",  icon: "arrow.up.right")
        }
    }

    private func typeButton(_ t: TransactionType, label: LocalizedStringKey, icon: String) -> some View {
        let selected = type == t
        let color: Color = t == .expense ? BrandColor.expense : BrandColor.income
        return Button {
            withAnimation(.spring(response: 0.25)) { type = t }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                Text(label).font(.brand(.subheadline))
            }
            .foregroundStyle(selected ? .white : BrandColor.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(selected ? color : BrandColor.surface.opacity(0.5))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(selected ? Color.clear : BrandColor.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category chips

    private var categoryChipsRow: some View {
        let filtered = categories.filter { $0.type == type }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(filtered) { cat in
                    categoryChip(cat)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }

    private func categoryChip(_ cat: Category) -> some View {
        let isSelected = cat.id == selectedCategory?.id
        let color = Color(hex: cat.colorHex)
        return Button {
            withAnimation(.spring(response: 0.25)) {
                selectedCategory = isSelected ? nil : cat
            }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isSelected ? 0.22 : 0.1))
                        .frame(width: 46, height: 46)
                        .overlay(Circle().stroke(isSelected ? color : Color.clear, lineWidth: 2))
                    Image(systemName: cat.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(color)
                }
                Text(cat.localizedDisplayName)
                    .font(.brand(.caption))
                    .foregroundStyle(isSelected ? BrandColor.textPrimary : BrandColor.textTertiary)
                    .lineLimit(1)
                    .frame(width: 56)
            }
            .frame(width: 56)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Amount display

    private var amountDisplay: some View {
        VStack(spacing: 4) {
            Text("TUTAR")
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
                .tracking(1.2)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("₺")
                    .font(.brand(.title))
                    .foregroundStyle(amountColor)
                Text(wholePart.isEmpty ? "0" : wholePart)
                    .font(.brand(.displayHero))
                    .foregroundStyle(amountColor)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.2), value: wholePart)
                if let frac = fracPart {
                    Text(",\(frac)_".prefix(frac.isEmpty ? 2 : frac.count + 1))
                        .font(.brand(.title))
                        .foregroundStyle(amountColor.opacity(0.7))
                }
            }
        }
    }

    // MARK: - Note field

    private var noteField: some View {
        let radius: CGFloat = isTyping ? 20 : Spacing.radiusSmall
        return HStack(alignment: isTyping ? .top : .center, spacing: Spacing.sm) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 14))
                .foregroundStyle(BrandColor.textTertiary)
                .padding(.top, isTyping ? 2 : 0)
            VStack(alignment: .leading, spacing: 0) {
                TextField("Açıklama ekle…", text: $note)
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textPrimary)
                    .tint(BrandColor.primary)
                    .submitLabel(.done)
                    .focused($noteFocused)
                    .onSubmit { noteFocused = false }
                if isTyping { Spacer(minLength: 0) }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .frame(maxHeight: isTyping ? .infinity : nil)
        .background(BrandColor.surface.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(noteFocused ? BrandColor.primary.opacity(0.5) : BrandColor.borderSubtle, lineWidth: 1)
        )
        .onChange(of: noteFocused) { _, v in isTyping = v }
    }

    // MARK: - Date row

    private var dateRow: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.system(size: 14))
                .foregroundStyle(BrandColor.textTertiary)
            Text("Tarih")
                .font(.brand(.body))
                .foregroundStyle(BrandColor.textTertiary)
            Spacer()
            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
                .colorScheme(.dark)
                .tint(BrandColor.primary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(BrandColor.surface.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous)
                .strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Category picker sheet

    private var editCategoryPicker: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()
                List {
                    Button {
                        selectedCategory = nil; showCategoryPicker = false
                    } label: {
                        HStack {
                            Text("Kategori yok").font(.brand(.body)).foregroundStyle(BrandColor.textPrimary)
                            Spacer()
                            if selectedCategory == nil {
                                Image(systemName: "checkmark").foregroundStyle(BrandColor.primary)
                            }
                        }
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.5))

                    ForEach(categories.filter { $0.type == type }) { cat in
                        Button {
                            selectedCategory = cat; showCategoryPicker = false
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Circle().fill(Color(hex: cat.colorHex)).frame(width: 10, height: 10)
                                Text(cat.localizedDisplayName).font(.brand(.body)).foregroundStyle(BrandColor.textPrimary)
                                Spacer()
                                if selectedCategory?.id == cat.id {
                                    Image(systemName: "checkmark").foregroundStyle(BrandColor.primary)
                                }
                            }
                        }
                        .listRowBackground(BrandColor.surface.opacity(0.5))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Kategori Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { showCategoryPicker = false }.foregroundStyle(BrandColor.primary)
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    private var isValid: Bool {
        let normalized = rawInput.replacingOccurrences(of: ",", with: ".")
        guard let val = Decimal(string: normalized), val > 0 else { return false }
        return true
    }

    private func loadFromTransaction() {
        note             = transaction.note
        type             = transaction.type
        selectedCategory = transaction.category
        date             = transaction.date
        isRecurring      = transaction.isRecurring
        // Convert Decimal to display string
        let str = "\(transaction.amount)"
        rawInput = str.contains(".") ? str.replacingOccurrences(of: ".", with: ",") : str
    }

    private func saveChanges() {
        let normalized = rawInput.replacingOccurrences(of: ",", with: ".")
        guard let val = Decimal(string: normalized), val > 0 else { return }
        transaction.note      = note
        transaction.amount    = val
        transaction.type      = type
        transaction.category  = selectedCategory
        transaction.date      = date
        transaction.isRecurring = isRecurring
        transaction.updatedAt = .now
        let tx = transaction
        Task { try? await FirestoreService.shared.uploadTransaction(tx) }
        dismiss()
    }
}
