//
//  OnboardingWelcomeView.swift
//  Budgetella
//
//  Adım 01 · Karşılama
//  Hero kart stack (float animasyonlu) + CTA + "Hesabın var mı?" linki.
//

import SwiftUI

struct OnboardingWelcomeView: View {

    var vm: OnboardingViewModel

    @State private var floatOffset: CGFloat = 0
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // ── Hero kart stack
            heroCards
                .padding(.bottom, Spacing.xxl)

            // ── Başlık
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Para,\nnihayet net.")
                    .font(.brand(.display))
                    .tracking(-1.5)
                    .foregroundStyle(BrandColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Her gelir-gideri saniyeler içinde gir.\nGerisini AI hallediyor.")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: appeared)

            Spacer()

            // ── CTA
            VStack(spacing: Spacing.lg) {
                Button {
                    vm.advance()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Text("Başlayalım")
                            .font(.brand(.subheadline))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [BrandColor.primary, BrandColor.primaryLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }

                Button {
                    // Auth flow'a yönlendir — şimdilik advance ile geç
                    // TODO: Auth sequence #5 hazır olunca direct route
                    vm.currentStep = 99
                } label: {
                    Text("Hesabın var mı? ")
                        .foregroundStyle(BrandColor.textSecondary)
                    + Text("Giriş yap")
                        .foregroundStyle(BrandColor.textPrimary)
                }
                .font(.brand(.footnote))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: appeared)
        }
        .onAppear {
            appeared = true
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
            ) {
                floatOffset = -8
            }
        }
    }

    // MARK: - Hero Cards

    private var heroCards: some View {
        ZStack {
            // Starbucks kart — sol üst
            transactionPill(
                vendor: "STARBUCKS",
                category: "Coffee",
                amount: "-₺85,50",
                isIncome: false
            )
            .rotationEffect(.degrees(-6))
            .offset(x: -60, y: -20)
            .offset(y: floatOffset * 0.6)

            // Freelance kart — sağ üst
            transactionPill(
                vendor: "FREELANCE",
                category: "Proje ödeme",
                amount: "+₺12.500",
                isIncome: true
            )
            .rotationEffect(.degrees(4))
            .offset(x: 50, y: 30)
            .offset(y: floatOffset)

            // AI Insight kart — alt orta
            aiInsightCard
                .offset(x: -20, y: 100)
                .offset(y: floatOffset * 0.8)
        }
        .frame(height: 260)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.85)
        .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1), value: appeared)
    }

    private func transactionPill(
        vendor: String,
        category: String,
        amount: String,
        isIncome: Bool
    ) -> some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vendor)
                    .font(.brand(.caption2))
                    .foregroundStyle(BrandColor.textTertiary)
                    .textCase(.uppercase)
                Text(category)
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textSecondary)
            }
            Spacer()
            Text(amount)
                .font(.brand(.subheadline))
                .foregroundStyle(isIncome ? BrandColor.income : BrandColor.expense)
                .monospacedDigit()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .frame(width: 200)
        .glassCard(cornerRadius: Spacing.radiusMedium, elevated: true)
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }

    private var aiInsightCard: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(BrandColor.primary.opacity(0.2))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BrandColor.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("AI INSIGHT")
                    .font(.brand(.caption2))
                    .foregroundStyle(BrandColor.primary)
                    .textCase(.uppercase)
                Text("Geçen aya göre ₺3.400\ntasarruf ettin. Aynen devam 🔥")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(BrandColor.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(width: 220, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [BrandColor.primary.opacity(0.15), BrandColor.background2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                        .strokeBorder(BrandColor.primary.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: BrandColor.primary.opacity(0.2), radius: 16, y: 8)
    }
}

#Preview {
    OnboardingWelcomeView(vm: OnboardingViewModel())
        .background(BrandColor.background)
        .preferredColorScheme(.dark)
}
