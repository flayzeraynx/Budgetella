//
//  PaywallView.swift
//  Budgetella
//
//  Full-screen premium paywall. $4.99/ay · $39.99/yıl · 7 gün trial.
//

import SwiftUI
import StoreKit

struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionService = SubscriptionService()
    @State private var selectedPlan: Plan = .yearly
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    enum Plan { case monthly, yearly }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [BrandColor.background3, BrandColor.background, BrandColor.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(BrandColor.surface.opacity(0.6))
                                .frame(width: 32, height: 32)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(BrandColor.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, Spacing.lg)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {

                        // Hero
                        heroSection

                        // Feature list
                        featureList

                        // Plan selector
                        planSelector

                        // CTA
                        ctaSection

                        // Fine print
                        finePrint
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await subscriptionService.setup() }
        .alert("Hata", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(BrandColor.primary.opacity(0.15))
                    .frame(width: 80, height: 80)
                Circle()
                    .fill(BrandColor.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BrandColor.primaryLight, BrandColor.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: Spacing.xs) {
                Text("Budgetella Premium")
                    .font(.brand(.largeTitle))
                    .foregroundStyle(BrandColor.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Finansal özgürlüğüne giden yolda\ntam kontrol")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: - Feature list

    private var featureList: some View {
        VStack(spacing: Spacing.sm) {
            featureRow(icon: "wand.and.sparkles", color: BrandColor.primary,
                       title: "Budgi AI Asistan",
                       subtitle: "Harcamalarını analiz et, tavsiyeleri al")
            featureRow(icon: "camera.viewfinder", color: BrandColor.info,
                       title: "Fiş OCR",
                       subtitle: "Kamerayla otomatik fiş kaydı")
            featureRow(icon: "chart.bar.doc.horizontal", color: BrandColor.income,
                       title: "Bütçe & Tahmin",
                       subtitle: "Aylık hedef koy, ay sonu tahmini gör")
            featureRow(icon: "square.and.arrow.up", color: BrandColor.warning,
                       title: "Gelişmiş Dışa Aktarma",
                       subtitle: "Excel, PDF ve JSON formatları")
            featureRow(icon: "infinity", color: BrandColor.primaryLight,
                       title: "Sınırsız İşlem",
                       subtitle: "Geçmişe dair tüm veriler, sınırsız")
        }
        .padding(Spacing.md)
        .glassCard(cornerRadius: Spacing.radiusMedium)
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.brand(.subheadline))
                    .foregroundStyle(BrandColor.textPrimary)
                Text(subtitle)
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(BrandColor.income)
        }
    }

    // MARK: - Plan selector

    private var planSelector: some View {
        VStack(spacing: Spacing.sm) {
            // Yearly plan
            planCard(
                plan: .yearly,
                title: "Yıllık Plan",
                price: "$39.99",
                period: "yıl",
                badge: "%33 tasarruf",
                subPrice: "$3.33/ay"
            )
            // Monthly plan
            planCard(
                plan: .monthly,
                title: "Aylık Plan",
                price: "$4.99",
                period: "ay",
                badge: nil,
                subPrice: nil
            )
        }
    }

    private func planCard(
        plan: Plan,
        title: String,
        price: String,
        period: String,
        badge: String?,
        subPrice: String?
    ) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            withAnimation(.spring(response: 0.3)) { selectedPlan = plan }
        } label: {
            HStack(spacing: Spacing.md) {
                // Radio button
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? BrandColor.primary : BrandColor.borderMedium,
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(BrandColor.primary)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xs) {
                        Text(title)
                            .font(.brand(.subheadline))
                            .foregroundStyle(BrandColor.textPrimary)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(BrandColor.income)
                                .clipShape(Capsule())
                        }
                    }
                    if let sub = subPrice {
                        Text(sub)
                            .font(.brand(.caption))
                            .foregroundStyle(BrandColor.textTertiary)
                    }
                }

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.brand(.headline))
                        .foregroundStyle(isSelected ? BrandColor.primary : BrandColor.textPrimary)
                    Text("/\(period)")
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.textTertiary)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                    .fill(isSelected ? BrandColor.primary.opacity(0.1) : BrandColor.surface.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                    .strokeBorder(
                        isSelected ? BrandColor.primary.opacity(0.5) : BrandColor.borderSubtle,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                Task { await startPurchase() }
            } label: {
                ZStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("7 Gün Ücretsiz Dene")
                            .font(.brand(.headline))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [BrandColor.primary, BrandColor.primaryLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
                .shadow(color: BrandColor.primary.opacity(0.4), radius: 16, y: 6)
            }
            .disabled(isPurchasing)

            Button {
                Task {
                    do {
                        try await subscriptionService.restorePurchases()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            } label: {
                Text("Satın Alımları Geri Yükle")
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Fine print

    private var finePrint: some View {
        VStack(spacing: 4) {
            Text("Deneme süresi bittikten sonra seçtiğin plan fiyatından otomatik yenilenir.")
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
                .multilineTextAlignment(.center)
            HStack(spacing: Spacing.md) {
                Link("Gizlilik Politikası", destination: URL(string: "https://budgetella.app/privacy")!)
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.primary.opacity(0.7))
                Link("Kullanım Koşulları", destination: URL(string: "https://budgetella.app/terms")!)
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.primary.opacity(0.7))
            }
        }
    }

    // MARK: - Purchase

    private func startPurchase() async {
        let product: Product? = selectedPlan == .yearly
            ? subscriptionService.yearlyProduct
            : subscriptionService.monthlyProduct
        guard let product else {
            errorMessage = "Ürün yüklenemedi. Lütfen tekrar deneyin."
            return
        }
        isPurchasing = true
        do {
            try await subscriptionService.purchase(product)
            if subscriptionService.isPremium { dismiss() }
        } catch {
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }
}
