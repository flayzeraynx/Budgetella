//
//  OnboardingCurrencyView.swift
//  Budgetella
//
//  Adım 03 · Para birimi
//  Flag + radio listesi. TRY varsayılan seçili.
//

import SwiftUI

struct OnboardingCurrencyView: View {

    var vm: OnboardingViewModel
    @State private var appeared = false

    private let currencies: [(currency: AppCurrency, flag: String, name: String)] = [
        (.tryLira, "🇹🇷", "Turkish Lira"),
        (.usd,     "🇺🇸", "US Dollar"),
        (.eur,     "🇪🇺", "Euro"),
        (.gbp,     "🇬🇧", "British Pound"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            stepHeader(current: 3, total: 4, onSkip: vm.skip)
                .padding(.horizontal, 28)
                .padding(.top, 16)

            Spacer()

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Pick your currency")
                    .font(.brand(.largeTitle))
                    .foregroundStyle(BrandColor.textPrimary)
                Text("You can change this later in Settings.")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.bottom, Spacing.xl)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

            // ── Currency listesi
            VStack(spacing: Spacing.sm) {
                ForEach(Array(currencies.enumerated()), id: \.element.currency.rawValue) { index, item in
                    currencyRow(item: item)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(0.15 + Double(index) * 0.07),
                            value: appeared
                        )
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            Button { vm.advance() } label: { primaryButtonLabel("Continue") }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.45), value: appeared)
        }
        .onAppear { appeared = true }
    }

    private func currencyRow(item: (currency: AppCurrency, flag: String, name: String)) -> some View {
        let isSelected = vm.selectedCurrency == item.currency

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                vm.selectedCurrency = item.currency
            }
        } label: {
            HStack(spacing: Spacing.lg) {
                Text(item.flag)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.brand(.subheadline))
                        .foregroundStyle(BrandColor.textPrimary)
                    Text("\(item.currency.rawValue) · \(item.currency.symbol)")
                        .font(.brand(.footnote))
                        .foregroundStyle(BrandColor.textTertiary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(BrandColor.primary)
                } else {
                    Circle()
                        .strokeBorder(BrandColor.borderMedium, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                    .fill(isSelected ? BrandColor.primary.opacity(0.1) : BrandColor.surface.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                            .strokeBorder(
                                isSelected ? BrandColor.primary.opacity(0.4) : BrandColor.borderSubtle,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        BrandColor.background.ignoresSafeArea()
        OnboardingCurrencyView(vm: OnboardingViewModel())
    }
    .preferredColorScheme(.dark)
}
