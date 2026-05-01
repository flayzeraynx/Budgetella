//
//  OnboardingFeaturesView.swift
//  Budgetella
//
//  Adım 02 · Özellikler
//  "Built for speed. Loved by your wallet." — 4 feature item.
//

import SwiftUI

struct OnboardingFeaturesView: View {

    var vm: OnboardingViewModel
    @State private var appeared = false

    private let features: [(icon: String, title: String, description: String)] = [
        ("mic.fill",
         "Talk it in",
         "\"100 lira gas\" — done. Voice → entry, instantly."),
        ("camera.fill",
         "Snap a receipt",
         "Camera reads the total, vendor, and category for you."),
        ("sparkles",
         "AI categorizer",
         "Every entry lands in the right bucket — no taps needed."),
        ("chart.bar.fill",
         "Real insights",
         "Trends, forecasts, and gentle nudges toward saving more."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // ── Üst bar
            stepHeader(current: 2, total: 4, onSkip: vm.skip)
                .padding(.horizontal, 28)
                .padding(.top, 16)

            Spacer()

            // ── Hero başlık
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Built for speed.")
                    .font(.brand(.largeTitle))
                    .foregroundStyle(BrandColor.textPrimary)
                Text("Loved by your wallet.")
                    .font(.brand(.largeTitle))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.bottom, Spacing.xxl)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

            // ── Feature listesi
            VStack(spacing: Spacing.md) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    featureRow(icon: feature.icon, title: feature.title, description: feature.description)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(0.15 + Double(index) * 0.08),
                            value: appeared
                        )
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            // ── CTA
            Button { vm.advance() } label: { primaryButtonLabel("Continue") }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.5), value: appeared)
        }
        .onAppear { appeared = true }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous)
                    .fill(BrandColor.primary.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(BrandColor.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.brand(.subheadline))
                    .foregroundStyle(BrandColor.textPrimary)
                Text(description)
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

#Preview {
    ZStack {
        BrandColor.background.ignoresSafeArea()
        OnboardingFeaturesView(vm: OnboardingViewModel())
    }
    .preferredColorScheme(.dark)
}
