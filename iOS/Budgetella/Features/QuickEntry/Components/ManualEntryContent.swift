//
//  ManualEntryContent.swift
//  Budgetella
//
//  Manuel işlem girişi: tip toggle → tutar → mod seçici → açıklama → kategori → numpad
//

import SwiftUI
import SwiftData

struct ManualEntryContent: View {

    @Bindable var vm: QuickEntryViewModel
    let categories: [Category]
    @Binding var mode: EntryMode
    @Binding var isTyping: Bool

    @Query private var settingsArr: [AppSettings]
    private var currencySymbol: String { settingsArr.first?.currency.symbol ?? "₺" }

    @FocusState private var noteFieldFocused: Bool
    @FocusState private var amountFocused: Bool
    @State private var amountText: String = ""

    var body: some View {
        VStack(spacing: 0) {

            // 1 ── Type toggle (Gider / Gelir)
            typeToggle
                .padding(.horizontal, 20)
                .padding(.top, Spacing.md)

            // 2 ── Amount display
            amountDisplay
                .padding(.horizontal, 20)
                .padding(.top, Spacing.lg)

            // 3 ── Description field (note)
            descriptionField
                .padding(.horizontal, 20)
                .padding(.top, Spacing.md)

            // 4 ── Recurring toggle + interval chips
            recurringRow
                .padding(.horizontal, 20)
                .padding(.top, Spacing.sm)

            // 5 ── Date row
            dateRow
                .padding(.horizontal, 20)
                .padding(.top, Spacing.sm)

            // 6 ── Category chips (now at the bottom — matches Android)
            categoryChipsRow
                .padding(.top, Spacing.sm)

            if !vm.aiSuggestions.isEmpty {
                aiSuggestionRow
                    .padding(.horizontal, 20)
                    .padding(.top, Spacing.xs)
            }

            Spacer(minLength: Spacing.lg)
        }
        .animation(.spring(response: 0.3), value: isTyping)
        .task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            amountFocused = true
        }
        .onAppear {
            let decimal = Locale.current.decimalSeparator ?? "."
            amountText = vm.rawInput.replacingOccurrences(of: ",", with: decimal)
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
                amountText = vm.rawInput.replacingOccurrences(of: ",", with: decimal2)
                return
            }
            if vm.rawInput != result { vm.rawInput = result }
        }
        .onChange(of: vm.rawInput) { _, newVal in
            let decimal = Locale.current.decimalSeparator ?? "."
            let synced = newVal.replacingOccurrences(of: ",", with: decimal)
            if amountText != synced { amountText = synced }
        }
    }

    // MARK: - Mode selector pills

    private var modeSelectorPills: some View {
        HStack(spacing: Spacing.xs) {
            modePill(.manual, icon: "keyboard",     label: "Manuel")
            modePill(.voice,  icon: "mic.fill",     label: "Sesli")
            modePill(.camera, icon: "camera.fill",  label: "Kamera")
        }
        .padding(3)
        .background(BrandColor.surface.opacity(0.4))
        .clipShape(Capsule())
    }

    private func modePill(_ m: EntryMode, icon: String, label: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { mode = m }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.brand(.caption))
            }
            .foregroundStyle(mode == m ? .white : BrandColor.textTertiary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(mode == m ? BrandColor.primary : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Type toggle

    private var typeToggle: some View {
        HStack(spacing: Spacing.sm) {
            typeButton(.expense, label: "Gider", icon: "arrow.down.right")
            typeButton(.income,  label: "Gelir",  icon: "arrow.up.right")
        }
    }

    private func typeButton(_ type: TransactionType, label: LocalizedStringKey, icon: String) -> some View {
        let selected = vm.transactionType == type
        let color: Color = type == .expense ? BrandColor.expense : BrandColor.income

        return Button {
            withAnimation(.spring(response: 0.25)) { vm.transactionType = type }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.brand(.subheadline))
            }
            .foregroundStyle(selected ? .white : BrandColor.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(selected ? color : BrandColor.surface.opacity(0.5))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(selected ? Color.clear : BrandColor.borderSubtle, lineWidth: 1)
            )
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
                    Text(vm.wholePart)
                        .font(.brand(.displayHero))
                        .foregroundStyle(amountColor)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.2), value: vm.wholePart)
                    if let frac = vm.fracPart {
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
            noteFieldFocused = false
            amountFocused = true
        }
    }

    private var amountColor: Color {
        vm.transactionType == .expense ? BrandColor.expense : BrandColor.income
    }

    // MARK: - Description field

    private var descriptionField: some View {
        let radius: CGFloat = Spacing.radiusSmall
        return HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 14))
                .foregroundStyle(BrandColor.textTertiary)
                .padding(.top, 3)

            ZStack(alignment: .topLeading) {
                if vm.note.isEmpty {
                    Text("Açıklama ekle…")
                        .font(.brand(.body))
                        .foregroundStyle(BrandColor.textSecondary)
                        .allowsHitTesting(false)
                }
                TextField("", text: $vm.note, axis: .vertical)
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textPrimary)
                    .tint(BrandColor.primary)
                    .lineLimit(2)
                    .submitLabel(.done)
                    .focused($noteFieldFocused)
                    .onSubmit { noteFieldFocused = false }
            }

        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .frame(minHeight: 64, maxHeight: 64, alignment: .topLeading)
        .background(BrandColor.surface.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(noteFieldFocused ? BrandColor.primary.opacity(0.5) : BrandColor.borderSubtle, lineWidth: 1)
        )
        .onChange(of: vm.note) { _, _ in vm.updateSuggestions() }
        .onChange(of: noteFieldFocused) { _, v in isTyping = v }
    }

    // MARK: - Category chips (horizontal scroll)

    private var categoryChipsRow: some View {
        let filtered = categories.filter {
            vm.transactionType == .expense ? $0.type == .expense : $0.type == .income
        }

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
        let isSelected = cat.id == vm.selectedCategoryId
        let color = Color(hex: cat.colorHex)

        return Button {
            withAnimation(.spring(response: 0.25)) {
                vm.selectedCategoryId = isSelected ? nil : cat.id
            }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isSelected ? 0.22 : 0.1))
                        .frame(width: 46, height: 46)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                        )
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

    // MARK: - Date row

    private var dateRow: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "calendar")
                .font(.system(size: 14))
                .foregroundStyle(BrandColor.textTertiary)
            Text("Tarih")
                .font(.brand(.body))
                .foregroundStyle(BrandColor.textSecondary)
            Spacer()
            // The compact DatePicker chip sits flush with the row; matches
            // the date pill the Android sheet uses next to its type toggle.
            DatePicker("", selection: $vm.date, displayedComponents: [.date])
                .datePickerStyle(.compact)
                .labelsHidden()
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
                Toggle("", isOn: $vm.isRecurring)
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
                        vm.isRecurring ? BrandColor.primary.opacity(0.4) : BrandColor.borderSubtle,
                        lineWidth: 1
                    )
            )

            if vm.isRecurring {
                HStack(spacing: Spacing.xs) {
                    ForEach(RecurringInterval.allCases, id: \.self) { interval in
                        intervalChip(interval)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3), value: vm.isRecurring)
    }

    private func intervalChip(_ interval: RecurringInterval) -> some View {
        let selected = vm.recurringInterval == interval
        return Button {
            withAnimation(.spring(response: 0.25)) {
                vm.recurringInterval = interval
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

    // MARK: - AI suggestion chips

    private var aiSuggestionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                Text("AI ÖNERDİ")
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.primary)
                    .tracking(0.8)
                    .padding(.trailing, 2)

                ForEach(vm.aiSuggestions, id: \.slug) { suggestion in
                    let cat = categories.first { $0.slug == suggestion.slug.rawValue }
                    let isSelected = cat?.id == vm.selectedCategoryId
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            vm.selectedCategoryId = isSelected ? nil : cat?.id
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(cat.map { Color(hex: $0.colorHex) } ?? BrandColor.primary)
                                .frame(width: 6, height: 6)
                            Text(cat?.localizedDisplayName ?? suggestion.slug.rawValue)
                                .font(.brand(.footnote))
                                .foregroundStyle(isSelected ? .white : BrandColor.textPrimary)
                            if suggestion.confidence < 1.0 {
                                Text("\(Int(suggestion.confidence * 100))%")
                                    .font(.brand(.caption))
                                    .foregroundStyle(isSelected ? .white.opacity(0.7) : BrandColor.textTertiary)
                            }
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 5)
                        .background(isSelected ? BrandColor.primary : BrandColor.surface.opacity(0.5))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(isSelected ? Color.clear : BrandColor.borderSubtle, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

