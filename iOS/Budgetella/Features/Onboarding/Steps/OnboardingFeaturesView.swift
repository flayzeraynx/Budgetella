//
//  OnboardingFeaturesView.swift
//  Budgetella
//
//  Adım 02 · Özellikler
//

import SwiftUI

struct OnboardingFeaturesView: View {

    var vm: OnboardingViewModel
    @State private var appeared = false

    private let features: [(icon: String, title: String, description: String)] = [
        ("mic.fill",
         "Sesle gir",
         "\"100 lira benzin\" — tamam. Sesini söyle, işlem anında kaydolsun."),
        ("camera.fill",
         "Fiş tara",
         "Kamera tutarı, marketi ve kategoriyi senin için okur."),
        ("sparkles",
         "AI kategorileme",
         "Her işlem doğru kategoriye düşer — tek dokunuş gerekmez."),
        ("chart.bar.fill",
         "Gerçek içgörüler",
         "Trendler, tahminler ve tasarruf için nazik hatırlatmalar."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            stepHeader(current: 2, total: 4, onSkip: vm.skip)
                .padding(.horizontal, 28)
                .padding(.top, 16)

            Spacer()

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Hız için yapıldı.")
                    .font(.brand(.largeTitle))
                    .foregroundStyle(BrandColor.textPrimary)
                Text("Cüzdanınız tarafından sevildi.")
                    .font(.brand(.largeTitle))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.bottom, Spacing.xxl)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

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

            Button { vm.advance() } label: { primaryButtonLabel("Devam") }
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
