//
//  EditTransactionSheet.swift
//  Budgetella
//
//  V2.1 cleanup #4: delete sheet only shows "Sil" (destructive) + "Vazgeç". No archive.
//

import SwiftUI
import SwiftData

struct EditTransactionSheet: View {

    @Bindable var transaction: Transaction
    let categories: [Category]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false
    @State private var showCategoryPicker = false

    // Editable copies
    @State private var note: String = ""
    @State private var amount: String = ""
    @State private var type: TransactionType = .expense
    @State private var selectedCategory: Category? = nil
    @State private var date: Date = .now
    @State private var isRecurring: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {

                        // Type toggle
                        typeToggle
                            .padding(.top, Spacing.sm)

                        // Amount field
                        amountField

                        // Fields
                        VStack(spacing: Spacing.sm) {
                            editField(label: "Not") {
                                TextField("Açıklama", text: $note)
                                    .font(.brand(.body))
                                    .foregroundStyle(BrandColor.textPrimary)
                                    .autocorrectionDisabled()
                            }

                            editField(label: "Kategori") {
                                Button {
                                    showCategoryPicker = true
                                } label: {
                                    HStack {
                                        if let cat = selectedCategory {
                                            Circle()
                                                .fill(Color(hex: cat.colorHex))
                                                .frame(width: 10, height: 10)
                                            Text(cat.name)
                                                .font(.brand(.body))
                                                .foregroundStyle(BrandColor.textPrimary)
                                        } else {
                                            Text("Seç")
                                                .font(.brand(.body))
                                                .foregroundStyle(BrandColor.textTertiary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(BrandColor.textTertiary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }

                            editField(label: "Tarih") {
                                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .tint(BrandColor.primary)
                            }
                        }

                        // Recurring toggle
                        recurringRow

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("İşlemi Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Vazgeç") { dismiss() }
                        .foregroundStyle(BrandColor.textTertiary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.md) {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundStyle(BrandColor.expense)
                        }

                        Button("Kaydet") {
                            saveChanges()
                        }
                        .font(.brand(.subheadline).bold())
                        .foregroundStyle(BrandColor.primary)
                        .disabled(!isValid)
                    }
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showCategoryPicker) {
                editCategoryPicker
            }
            .confirmationDialog("İşlemi sil?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Sil", role: .destructive) {
                    modelContext.delete(transaction)
                    dismiss()
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Bu işlem kalıcı olarak silinecek.")
            }
        }
        .onAppear { loadFromTransaction() }
    }

    // MARK: - Type toggle

    private var typeToggle: some View {
        HStack(spacing: 0) {
            ForEach([TransactionType.expense, .income], id: \.self) { t in
                Button {
                    withAnimation(.spring(response: 0.28)) { type = t }
                } label: {
                    Text(t == .expense ? "Gider" : "Gelir")
                        .font(.brand(.subheadline))
                        .foregroundStyle(type == t ? .white : BrandColor.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            type == t
                            ? (t == .expense ? BrandColor.expense : BrandColor.income)
                            : Color.clear
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(BrandColor.surface.opacity(0.5))
        .clipShape(Capsule())
    }

    // MARK: - Amount field

    private var amountField: some View {
        VStack(spacing: Spacing.xs) {
            Text("Tutar")
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
                .tracking(0.8)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("₺")
                    .font(.brand(.title))
                    .foregroundStyle(BrandColor.textTertiary)
                TextField("0", text: $amount)
                    .font(.system(size: 38, weight: .bold).monospacedDigit())
                    .foregroundStyle(BrandColor.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 200)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .glassCard(cornerRadius: Spacing.radiusMedium)
    }

    // MARK: - Edit field wrapper

    private func editField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.brand(.footnote))
                .foregroundStyle(BrandColor.textTertiary)
                .frame(width: 80, alignment: .leading)
            content()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .glassCard(cornerRadius: Spacing.radiusMedium)
    }

    // MARK: - Recurring

    private var recurringRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tekrarlayan")
                    .font(.brand(.subheadline))
                    .foregroundStyle(BrandColor.textPrimary)
                Text("Aylık otomatik işlem")
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            Spacer()
            Toggle("", isOn: $isRecurring)
                .tint(BrandColor.primary)
                .labelsHidden()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .glassCard(cornerRadius: Spacing.radiusMedium)
    }

    // MARK: - Category picker sheet

    private var editCategoryPicker: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()
                List {
                    Button {
                        selectedCategory = nil
                        showCategoryPicker = false
                    } label: {
                        HStack {
                            Text("Kategori yok")
                                .font(.brand(.body))
                                .foregroundStyle(BrandColor.textPrimary)
                            Spacer()
                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(BrandColor.primary)
                            }
                        }
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.5))

                    ForEach(categories.filter { $0.type == type }) { cat in
                        Button {
                            selectedCategory = cat
                            showCategoryPicker = false
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Circle()
                                    .fill(Color(hex: cat.colorHex))
                                    .frame(width: 10, height: 10)
                                Text(cat.name)
                                    .font(.brand(.body))
                                    .foregroundStyle(BrandColor.textPrimary)
                                Spacer()
                                if selectedCategory?.id == cat.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(BrandColor.primary)
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
                    Button("Kapat") { showCategoryPicker = false }
                        .foregroundStyle(BrandColor.primary)
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    private var isValid: Bool {
        guard let val = Decimal(string: amount.replacingOccurrences(of: ",", with: ".")),
              val > 0 else { return false }
        return true
    }

    private func loadFromTransaction() {
        note = transaction.note
        amount = "\(transaction.amount)"
        type = transaction.type
        selectedCategory = transaction.category
        date = transaction.date
        isRecurring = transaction.isRecurring
    }

    private func saveChanges() {
        guard let val = Decimal(string: amount.replacingOccurrences(of: ",", with: ".")) else { return }
        transaction.note = note
        transaction.amount = val
        transaction.type = type
        transaction.category = selectedCategory
        transaction.date = date
        transaction.isRecurring = isRecurring
        transaction.updatedAt = .now
        dismiss()
    }
}
