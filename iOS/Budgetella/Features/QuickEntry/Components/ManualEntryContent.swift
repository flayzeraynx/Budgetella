//
//  ManualEntryContent.swift
//  Budgetella
//
//  Manuel işlem girişi — tip toggle + tutar + açıklama + AI önerisi + numpad
//

import SwiftUI
import SwiftData

struct ManualEntryContent: View {

    @Bindable var vm: QuickEntryViewModel
    let categories: [Category]

    var body: some View {
        VStack(spacing: 0) {

            // ── Type toggle (Gider / Gelir)
            typeToggle
                .padding(.horizontal, 28)
                .padding(.top, Spacing.xl)

            Spacer(minLength: Spacing.xl)

            // ── Amount display
            amountDisplay
                .padding(.horizontal, 28)

            Spacer(minLength: Spacing.lg)

            // ── Description field
            descriptionField
                .padding(.horizontal, 28)

            // ── AI suggestion chips
            if !vm.aiSuggestions.isEmpty || vm.selectedCategoryId != nil {
                aiSuggestionRow
                    .padding(.horizontal, 28)
                    .padding(.top, Spacing.md)
            }

            Spacer(minLength: Spacing.xl)

            // ── Numpad
            NumpadGrid(
                onDigit:   { vm.appendDigit($0) },
                onDecimal: { vm.appendDecimal() },
                onDelete:  { vm.backspace() }
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Type toggle

    private var typeToggle: some View {
        HStack(spacing: Spacing.sm) {
            typeButton(.expense, label: "Gider", icon: "arrow.down.right")
            typeButton(.income,  label: "Gelir",  icon: "arrow.up.right")
        }
    }

    private func typeButton(_ type: TransactionType, label: String, icon: String) -> some View {
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
            .frame(height: 40)
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
        VStack(spacing: 4) {
            Text("TUTAR")
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
                .tracking(1.2)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("₺")
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
    }

    private var amountColor: Color {
        vm.transactionType == .expense ? BrandColor.expense : BrandColor.income
    }

    // MARK: - Description field

    private var descriptionField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 14))
                .foregroundStyle(BrandColor.textTertiary)
            TextField("Açıklama ekle…", text: $vm.note)
                .font(.brand(.body))
                .foregroundStyle(BrandColor.textPrimary)
                .tint(BrandColor.primary)
                .submitLabel(.done)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(BrandColor.surface.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous)
                .strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
        )
        .onChange(of: vm.note) { _, _ in vm.updateSuggestions() }
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
                            Text(cat?.name ?? suggestion.slug.rawValue)
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

                Button {
                    vm.showCategoryPicker = true
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .semibold))
                        Text("Diğer")
                            .font(.brand(.footnote))
                    }
                    .foregroundStyle(BrandColor.textSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 5)
                    .background(BrandColor.surface.opacity(0.3))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(BrandColor.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Numpad Grid

struct NumpadGrid: View {

    let onDigit:   (String) -> Void
    let onDecimal: () -> Void
    let onDelete:  () -> Void

    private let layout: [[String]] = [
        ["1","2","3"],
        ["4","5","6"],
        ["7","8","9"],
        [",","0","⌫"]
    ]

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(layout, id: \.self) { row in
                HStack(spacing: Spacing.sm) {
                    ForEach(row, id: \.self) { key in
                        numpadKey(key)
                    }
                }
            }
        }
    }

    private func numpadKey(_ key: String) -> some View {
        Button {
            switch key {
            case "⌫": onDelete()
            case ",": onDecimal()
            default:  onDigit(key)
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous)
                    .fill(key == "⌫" ? BrandColor.expense.opacity(0.12) : BrandColor.surface.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous)
                            .strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
                    )

                if key == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(BrandColor.expense)
                } else {
                    Text(key)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(BrandColor.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
        .buttonStyle(.plain)
    }
}
