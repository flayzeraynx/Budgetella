//
//  PickerSheets.swift
//  Budgetella
//
//  Tema / Dil / Para birimi seçici sheet'leri.
//

import SwiftUI

// MARK: - Theme Picker

struct ThemePickerSheet: View {

    var settings: AppSettings?
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var appTheme = "system"

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()
                List(AppTheme.allCases, id: \.self) { theme in
                    Button {
                        appTheme = theme.rawValue
                        settings?.theme = theme
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: themeIcon(theme))
                                .foregroundStyle(BrandColor.primary)
                                .frame(width: 24)
                            Text(themeLabel(theme))
                                .font(.brand(.body))
                                .foregroundStyle(BrandColor.textPrimary)
                            Spacer()
                            if settings?.theme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(BrandColor.primary)
                            }
                        }
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.5))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Tema")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(BrandColor.primary)
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func themeLabel(_ t: AppTheme) -> String {
        switch t {
        case .dark: return "Koyu"
        case .light: return "Açık"
        case .system: return "Sistem"
        }
    }

    private func themeIcon(_ t: AppTheme) -> String {
        switch t {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "circle.lefthalf.filled"
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
                List(AppLanguage.allCases, id: \.self) { lang in
                    Button {
                        settings?.language = lang
                        dismiss()
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Text(lang.flagEmoji)
                                .font(.system(size: 22))
                            Text(lang.displayName)
                                .font(.brand(.body))
                                .foregroundStyle(BrandColor.textPrimary)
                            Spacer()
                            if settings?.language == lang {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(BrandColor.primary)
                            }
                        }
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.5))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Dil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(BrandColor.primary)
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Currency Picker

struct CurrencyPickerSheet: View {

    var settings: AppSettings?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()
                List(AppCurrency.allCases, id: \.self) { currency in
                    Button {
                        settings?.currency = currency
                        dismiss()
                    } label: {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(BrandColor.primary.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Text(currency.symbol)
                                    .font(.brand(.headline))
                                    .foregroundStyle(BrandColor.primary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(currency.rawValue)
                                    .font(.brand(.body))
                                    .foregroundStyle(BrandColor.textPrimary)
                                Text(currencyName(currency))
                                    .font(.brand(.caption))
                                    .foregroundStyle(BrandColor.textTertiary)
                            }
                            Spacer()
                            if settings?.currency == currency {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(BrandColor.primary)
                            }
                        }
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.5))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Para Birimi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(BrandColor.primary)
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func currencyName(_ c: AppCurrency) -> String {
        switch c {
        case .tryLira: return "Türk Lirası"
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        }
    }
}
