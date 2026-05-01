//
//  BudgiView.swift
//  Budgetella
//
//  AI tab — Budgi finans koçu. Chat MVP sonrası (V1.1). Proaktif insight'lar burada.
//

import SwiftUI

struct BudgiView: View {

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [BrandColor.primary, BrandColor.primaryLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 36, height: 36)
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Budgi")
                                .font(.brand(.headline))
                                .foregroundStyle(BrandColor.textPrimary)
                            HStack(spacing: 3) {
                                Circle().fill(BrandColor.income).frame(width: 5, height: 5)
                                Text("Senin finans asistanın")
                                    .font(.brand(.caption))
                                    .foregroundStyle(BrandColor.textTertiary)
                            }
                        }
                        Spacer()
                        Text("PREMIUM")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(BrandColor.primary)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, Spacing.md)
                    .background(BrandColor.background)

                    Divider().background(BrandColor.borderSubtle)

                    // Mock insight messages
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            // AI greeting bubble
                            assistantBubble {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text("Merhaba Ozzy 👋 Bu hafta şunları fark ettim:")
                                        .font(.brand(.body))
                                        .foregroundStyle(BrandColor.textPrimary)
                                }
                            }

                            // Anomaly card
                            assistantBubble(accent: BrandColor.expense) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(BrandColor.expense)
                                        Text("ANOMALİ")
                                            .font(.brand(.caption))
                                            .foregroundStyle(BrandColor.expense)
                                            .tracking(0.8)
                                    }
                                    Text("Yiyecek harcaman **%34 arttı** (₺4,280 → geçen hafta ₺3,180). Çoğu dışarıdan yemek.")
                                        .font(.brand(.footnote))
                                        .foregroundStyle(BrandColor.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            // Suggestion card
                            assistantBubble(accent: BrandColor.income) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(BrandColor.income)
                                        Text("ÖNERİ")
                                            .font(.brand(.caption))
                                            .foregroundStyle(BrandColor.income)
                                            .tracking(0.8)
                                    }
                                    Text("Haftada 2 yemeği evde yapsan ay sonuna ~₺680 artar.")
                                        .font(.brand(.footnote))
                                        .foregroundStyle(BrandColor.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            // Premium lock overlay
                            premiumGateCard
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, Spacing.lg)
                        .padding(.bottom, 100)
                    }

                    // Chat input (locked)
                    chatInputBar
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
    }

    private func assistantBubble<Content: View>(accent: Color = BrandColor.surface, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [BrandColor.primary, BrandColor.primaryLight], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading) {
                content()
            }
            .padding(Spacing.md)
            .background(BrandColor.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                    .strokeBorder(accent.opacity(0.3), lineWidth: 1)
            )
            Spacer()
        }
    }

    private var premiumGateCard: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "lock.fill")
                .font(.system(size: 24))
                .foregroundStyle(BrandColor.primary)
            Text("Budgi ile sohbet Premium özelliği")
                .font(.brand(.subheadline))
                .foregroundStyle(BrandColor.textPrimary)
                .multilineTextAlignment(.center)
            Text("Harcamalarını analiz et, sorular sor, finansal hedeflerine ulaş.")
                .font(.brand(.footnote))
                .foregroundStyle(BrandColor.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: Spacing.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                .strokeBorder(BrandColor.primary.opacity(0.2), lineWidth: 1)
        )
    }

    private var chatInputBar: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Text("Budgi'ye soru sor...")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textTertiary)
                Spacer()
                Image(systemName: "mic")
                    .font(.system(size: 16))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(BrandColor.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusFull))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusFull)
                    .strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
            )

            ZStack {
                Circle()
                    .fill(BrandColor.primary)
                    .frame(width: 40, height: 40)
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, Spacing.sm)
        .padding(.bottom, 28)
        .background(BrandColor.background.opacity(0.95))
        .overlay(alignment: .top) {
            Divider().background(BrandColor.borderSubtle)
        }
        .disabled(true)
        .opacity(0.6)
    }
}
