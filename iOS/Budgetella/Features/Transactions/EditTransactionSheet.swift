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

    @Query private var settingsArr: [AppSettings]
    private var currencySymbol: String { settingsArr.first?.currency.symbol ?? "₺" }

    @State private var showDeleteConfirm = false
    @State private var showCategoryPicker = false

    // Editable state
    @State private var note:             String           = ""
    @State private var rawInput:         String           = ""   // numpad input
    @State private var type:             TransactionType  = .expense
    @State private var selectedCategory: Category?        = nil
    @State private var date:             Date             = .now
    @State private var isRecurring:        Bool               = false
    @State private var recurringInterval:  RecurringInterval  = .monthly
    @State private var recurringEndDate:   Date?              = nil
    @State private var isTyping:           Bool               = false
    @State private var showRecurringScope: Bool               = false
    @State private var pendingAmount:      Decimal?           = nil

    @FocusState private var noteFocused: Bool
    @FocusState private var amountFocused: Bool
    @State private var amountText: String = ""

    // MARK: - Computed amount helpers

    private var wholePart: String {
        let intStr = rawInput.components(separatedBy: ",").first ?? "0"
        guard let intValue = Int(intStr) else { return intStr.isEmpty ? "0" : intStr }
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.groupingSeparator = "."
        fmt.usesGroupingSeparator = true
        return fmt.string(from: NSNumber(value: intValue)) ?? intStr
    }
    private var fracPart: String? {
        guard rawInput.contains(",") else { return nil }
        return rawInput.components(separatedBy: ",").last ?? ""
    }
    private var amountColor: Color { type == .expense ? BrandColor.expense : BrandColor.income }

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

                                // 6 — Recurring toggle + interval chips
                                recurringRow
                                    .padding(.horizontal, 20)
                                    .padding(.top, Spacing.xs)
                            }
                        }
                        .padding(.bottom, Spacing.sm)
                    }

                    if !isTyping {
                        // 6 — Save button
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Bitti") {
                        amountFocused = false
                        noteFocused = false
                    }
                    .font(.brand(.subheadline))
                    .foregroundStyle(BrandColor.primary)
                }
            }
            .onChange(of: amountText) { _, newVal in
                let decimal = Locale.current.decimalSeparator ?? "."
                let normalized = newVal
                    .replacingOccurrences(of: decimal, with: ",")
                    .replacingOccurrences(of: ".", with: ",")
                let filtered = String(normalized.filter { $0.isNumber || $0 == "," })
                let parts = filtered.components(separatedBy: ",")
                var result: String
                if parts.count >= 2 {
                    result = parts[0] + "," + String(parts[1].prefix(2))
                } else {
                    result = filtered
                }
                guard result.filter({ $0.isNumber }).count <= 10 else {
                    let decimal2 = Locale.current.decimalSeparator ?? "."
                    amountText = rawInput.replacingOccurrences(of: ",", with: decimal2)
                    return
                }
                if rawInput != result { rawInput = result }
            }
            .onChange(of: rawInput) { _, newVal in
                let decimal = Locale.current.decimalSeparator ?? "."
                let synced = newVal.replacingOccurrences(of: ",", with: decimal)
                if amountText != synced { amountText = synced }
            }
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
            .confirmationDialog(
                "Tekrarlayan İşlemi Düzenle",
                isPresented: $showRecurringScope,
                titleVisibility: .visible
            ) {
                if transaction.originalTransactionId == nil {
                    // Editing the template — offer: this record only vs all in series
                    Button("Sadece Bu Kaydı") {
                        if let amt = pendingAmount { performSave(amount: amt, scope: .thisOnly) }
                    }
                    Button("Tüm Seriyi Güncelle") {
                        if let amt = pendingAmount { performSave(amount: amt, scope: .allInSeries) }
                    }
                } else {
                    // Editing a derived instance — offer: this record only vs template too
                    Button("Sadece Bu Kaydı") {
                        if let amt = pendingAmount { performSave(amount: amt, scope: .thisOnly) }
                    }
                    Button("Şablonu da Güncelle") {
                        if let amt = pendingAmount { performSave(amount: amt, scope: .templateToo) }
                    }
                }
                Button("Vazgeç", role: .cancel) { pendingAmount = nil }
            } message: {
                Text("Bu değişiklikleri nasıl uygulamak istersin?")
            }
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
        ZStack {
            VStack(spacing: 4) {
                Text("TUTAR")
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
                    .tracking(1.2)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(currencySymbol)
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
            // Hidden text field captures numeric keyboard input
            TextField("", text: $amountText)
                .keyboardType(.decimalPad)
                .focused($amountFocused)
                .opacity(0.001)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            noteFocused = false
            amountFocused = true
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

    // MARK: - Recurring row

    private var recurringRow: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Image(systemName: "repeat.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(BrandColor.textTertiary)
                Text("Tekrarlayan işlem")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textSecondary)
                Spacer()
                Toggle("", isOn: $isRecurring)
                    .labelsHidden()
                    .tint(BrandColor.primary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(BrandColor.surface.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous)
                    .strokeBorder(
                        isRecurring ? BrandColor.primary.opacity(0.4) : BrandColor.borderSubtle,
                        lineWidth: 1
                    )
            )

            if isRecurring {
                HStack(spacing: Spacing.xs) {
                    ForEach(RecurringInterval.allCases, id: \.self) { interval in
                        intervalChip(interval)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3), value: isRecurring)
    }

    private func intervalChip(_ interval: RecurringInterval) -> some View {
        let selected = recurringInterval == interval
        return Button {
            withAnimation(.spring(response: 0.25)) {
                recurringInterval = interval
            }
        } label: {
            Text(interval.localizedLabel)
                .font(.brand(.subheadline))
                .foregroundStyle(selected ? .white : BrandColor.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(selected ? BrandColor.primary : BrandColor.surface.opacity(0.5))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(selected ? Color.clear : BrandColor.borderSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
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
        note              = transaction.note
        type              = transaction.type
        selectedCategory  = transaction.category
        date              = transaction.date
        isRecurring       = transaction.isRecurring
        recurringInterval = transaction.recurringInterval ?? .monthly
        recurringEndDate  = transaction.recurringEndDate
        // Convert Decimal to display string
        let str = "\(transaction.amount)"
        rawInput = str.contains(".") ? str.replacingOccurrences(of: ".", with: ",") : str
        let decimal = Locale.current.decimalSeparator ?? "."
        amountText = rawInput.replacingOccurrences(of: ",", with: decimal)
    }

    private func saveChanges() {
        let normalized = rawInput.replacingOccurrences(of: ",", with: ".")
        guard let val = Decimal(string: normalized), val > 0 else { return }
        // If the original transaction was already recurring, ask the user
        // which scope to apply before committing any changes.
        if transaction.isRecurring {
            pendingAmount = val
            showRecurringScope = true
            return
        }
        performSave(amount: val, scope: .thisOnly)
    }

    private func performSave(amount: Decimal, scope: RecurringEditScope) {
        // Snapshot the original template link before we mutate anything.
        let originalId = transaction.originalTransactionId

        // ── Apply changes to this transaction ───────────────────────────────
        transaction.note              = note
        transaction.amount            = amount
        transaction.type              = type
        transaction.category          = selectedCategory
        transaction.date              = date
        transaction.isRecurring       = isRecurring
        transaction.recurringInterval = isRecurring ? recurringInterval : nil
        transaction.recurringEndDate  = isRecurring ? recurringEndDate  : nil
        // If recurring was turned off, detach from series.
        if !isRecurring { transaction.originalTransactionId = nil }
        transaction.updatedAt         = .now
        let mainTx = transaction
        Task { try? await FirestoreService.shared.uploadTransaction(mainTx) }

        // ── Scope fan-out ────────────────────────────────────────────────────
        switch scope {

        case .thisOnly:
            break   // already saved above

        case .allInSeries:
            // Template is being edited — propagate to all derived instances.
            // Each instance keeps its own date; only shared fields are updated.
            let templateId = transaction.id
            if let all = try? modelContext.fetch(FetchDescriptor<Transaction>()) {
                for instance in all where instance.originalTransactionId == templateId {
                    instance.note              = note
                    instance.amount            = amount
                    instance.type              = type
                    instance.category          = selectedCategory
                    instance.isRecurring       = isRecurring
                    instance.recurringInterval = isRecurring ? recurringInterval : nil
                    instance.recurringEndDate  = isRecurring ? recurringEndDate  : nil
                    if !isRecurring { instance.originalTransactionId = nil }
                    instance.updatedAt         = .now
                    let tx = instance
                    Task { try? await FirestoreService.shared.uploadTransaction(tx) }
                }
            }

        case .templateToo:
            // Derived instance is being edited — propagate changes up to the template.
            // Template keeps its own date.
            if let tplId = originalId,
               let all  = try? modelContext.fetch(FetchDescriptor<Transaction>()),
               let tpl  = all.first(where: { $0.id == tplId }) {
                tpl.note              = note
                tpl.amount            = amount
                tpl.type              = type
                tpl.category          = selectedCategory
                tpl.isRecurring       = isRecurring
                tpl.recurringInterval = isRecurring ? recurringInterval : nil
                tpl.recurringEndDate  = isRecurring ? recurringEndDate  : nil
                tpl.updatedAt         = .now
                let tx = tpl
                Task { try? await FirestoreService.shared.uploadTransaction(tx) }
            }
        }

        pendingAmount = nil
        dismiss()
    }
}

// MARK: - RecurringEditScope

private enum RecurringEditScope {
    /// Save changes only to the transaction that was opened for editing.
    case thisOnly
    /// Template edit: update the template + all derived instances (each keeps its own date).
    case allInSeries
    /// Instance edit: update this instance + propagate back to its template (template keeps its own date).
    case templateToo
}
