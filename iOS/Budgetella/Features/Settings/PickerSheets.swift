//
//  PickerSheets.swift
//  Budgetella
//
//  Tema / Dil / Para birimi seçici sheet'leri — redesigned.
//

import SwiftUI

// MARK: - Theme Picker

struct ThemePickerSheet: View {

    var settings: AppSettings?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Options
                        VStack(spacing: Spacing.xs) {
                            let active = settings?.theme ?? .dark
                            themeRow(.dark,   icon: "moon.fill",             isCurrentlyActive: active == .dark)
                            themeRow(.light,  icon: "sun.max.fill",           isCurrentlyActive: active == .light)
                            themeRow(.system, icon: "circle.lefthalf.filled", isCurrentlyActive: active == .system)
                        }
                        .padding(.horizontal, 20)

                        // Preview
                        previewSection
                            .padding(.horizontal, 20)
                            .padding(.top, Spacing.xl)
                    }
                    .padding(.bottom, Spacing.xxxl)
                }
            }
            .navigationTitle("Tema")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tamam") { dismiss() }
                        .font(.brand(.subheadline).bold())
                        .foregroundStyle(BrandColor.primary)
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func themeRow(_ theme: AppTheme, icon: String, isCurrentlyActive: Bool) -> some View {
        let isActive = settings?.theme == theme
        return Button {
            settings?.theme = theme
            settings?.updatedAt = .now
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isActive ? BrandColor.primary : BrandColor.surface.opacity(0.5))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isActive ? .white : BrandColor.textTertiary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(themeLabel(theme))
                        .font(.brand(.body))
                        .foregroundStyle(BrandColor.textPrimary)
                    if isCurrentlyActive {
                        Text("Şu an aktif")
                            .font(.brand(.caption))
                            .foregroundStyle(isActive ? BrandColor.primary : BrandColor.textTertiary)
                    }
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BrandColor.primary)
                }
            }
            .padding(Spacing.md)
            .glassCard(cornerRadius: 14)
        }
        .buttonStyle(.plain)
        .cardHighlightOnPress(cornerRadius: 14)
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("ÖNİZLEME")
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
                .tracking(1.2)

            HStack(spacing: Spacing.sm) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "#1A1B2E"))
                    .frame(height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
                    )

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "#F5F6FE"))
                    .frame(height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
                    )

                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(BrandColor.primary)
                        .frame(height: 56)
                    Text("A")
                        .font(.brand(.headline))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func themeLabel(_ t: AppTheme) -> LocalizedStringKey {
        switch t {
        case .dark:   return "Karanlık"
        case .light:  return "Açık"
        case .system: return "Sistem"
        }
    }
}

// MARK: - Language Picker

struct LanguagePickerSheet: View {

    var settings: AppSettings?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xs) {
                        ForEach(AppLanguage.v1Cases, id: \.self) { lang in
                            languageRow(lang)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, Spacing.lg)

                    // Footer note
                    Text("Dil değişikliği anında uygulanır. Para birimi formatı dilden bağımsız ayrıca seçilebilir.")
                        .font(.brand(.footnote))
                        .foregroundStyle(BrandColor.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, Spacing.xl)
                        .padding(.bottom, Spacing.xxxl)
                }
            }
            .navigationTitle("Dil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tamam") { dismiss() }
                        .font(.brand(.subheadline).bold())
                        .foregroundStyle(BrandColor.primary)
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func applyLanguage(_ lang: AppLanguage) {
        settings?.language = lang
        settings?.updatedAt = .now
        UserDefaults.standard.set([lang.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        dismiss()
        // Slight delay so sheet dismiss animation completes before root rebuild
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
        }
    }

    private func languageRow(_ lang: AppLanguage) -> some View {
        let isActive = settings?.language == lang
        return Button {
            applyLanguage(lang)
        } label: {
            HStack(spacing: Spacing.md) {
                Text(lang.flagEmoji)
                    .font(.system(size: 28))
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.displayName)
                        .font(.brand(.body))
                        .foregroundStyle(BrandColor.textPrimary)
                    if isActive {
                        Text("Şu an aktif")
                            .font(.brand(.caption))
                            .foregroundStyle(BrandColor.primary)
                    }
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BrandColor.primary)
                }
            }
            .padding(Spacing.md)
            .glassCard(cornerRadius: 14)
        }
        .buttonStyle(.plain)
        .cardHighlightOnPress(cornerRadius: 14)
    }
}

// MARK: - Currency Picker

struct CurrencyPickerSheet: View {

    var settings: AppSettings?
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    /// V1: TRY + USD only. EUR/GBP unlock with V2 multi-currency.
    private let v1Currencies: [AppCurrency] = [.tryLira, .usd]

    private var filteredCurrencies: [AppCurrency] {
        guard !search.isEmpty else { return v1Currencies }
        let q = search.lowercased()
        return v1Currencies.filter {
            $0.rawValue.lowercased().contains(q) ||
            currencyNameRaw($0).lowercased().contains(q) ||
            $0.symbol.contains(q)
        }
    }

    private func currencyNameRaw(_ c: AppCurrency) -> String {
        switch c {
        case .tryLira: return "Türk Lirası"
        case .usd:     return "US Dollar"
        case .eur:     return "Euro"
        case .gbp:     return "British Pound"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search field
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundStyle(BrandColor.textTertiary)
                        TextField("Para birimi ara", text: $search)
                            .font(.brand(.body))
                            .foregroundStyle(BrandColor.textPrimary)
                            .tint(BrandColor.primary)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .glassCard(cornerRadius: 12)
                    .padding(.horizontal, 20)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)

                    ScrollView {
                        VStack(spacing: Spacing.xs) {
                            ForEach(filteredCurrencies, id: \.self) { currency in
                                currencyRow(currency)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, Spacing.xxxl)
                    }
                }
            }
            .navigationTitle("Para Birimi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tamam") { dismiss() }
                        .font(.brand(.subheadline).bold())
                        .foregroundStyle(BrandColor.primary)
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func currencyRow(_ currency: AppCurrency) -> some View {
        let isActive = settings?.currency == currency
        return Button {
            settings?.currency = currency
            settings?.updatedAt = .now
            // Persist symbol so Decimal.compactTRY/fullTRY can read it without ModelContext
            UserDefaults.standard.set(currency.symbol, forKey: "selectedCurrencySymbol")
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isActive ? BrandColor.primary : BrandColor.primary.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Text(currency.symbol)
                        .font(.brand(.headline))
                        .foregroundStyle(isActive ? .white : BrandColor.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(currencyName(currency))
                        .font(.brand(.body))
                        .foregroundStyle(BrandColor.textPrimary)
                    Text(currency.rawValue)
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.textTertiary)
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BrandColor.primary)
                }
            }
            .padding(Spacing.md)
            .glassCard(cornerRadius: 14)
        }
        .buttonStyle(.plain)
        .cardHighlightOnPress(cornerRadius: 14)
    }

    private func currencyName(_ c: AppCurrency) -> LocalizedStringKey {
        switch c {
        case .tryLira: return "Türk Lirası"
        case .usd:     return "US Dollar"
        case .eur:     return "Euro"
        case .gbp:     return "British Pound"
        }
    }
}
