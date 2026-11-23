//
//  PaywallView.swift
//  Budgetella
//
//  Full-screen premium paywall. $4.99/ay · $39.99/yıl · $99.99 ömür boyu · 7 gün trial.
//

import SwiftUI
import StoreKit

struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @AppStorage("currentUserId") private var currentUserId = ""
    /// Feature the user tapped to get here — listed first and highlighted.
    var context: PremiumFeature? = nil

    private var subscriptionService: SubscriptionService { .shared }
    @State private var selectedPlan: Plan = .yearly
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    enum Plan { case monthly, yearly, lifetime }

    var body: some View {
        ZStack {
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
                    Button { dismiss() } label: {
                        ZStack {
                            Circle()
                                .fill(BrandColor.surface.opacity(0.6))
                                .frame(width: 32, height: 32)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(BrandColor.textTertiary)
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel(Text("Kapat"))
                }
                .padding(.horizontal, 14)
                .padding(.top, Spacing.sm)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        heroSection
                        featureList
                        planSelector
                        ctaSection
                        finePrint
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
        }
        .task { await subscriptionService.setup(userId: currentUserId) }
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

    /// Rendered from `PremiumFeature` — exactly what is locked, nothing else.
    private var orderedFeatures: [PremiumFeature] {
        guard let context else { return PremiumFeature.allCases }
        return [context] + PremiumFeature.allCases.filter { $0 != context }
    }

    private var featureList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(orderedFeatures) { feature in
                featureRow(icon: feature.icon, color: feature.color,
                           title: feature.title, subtitle: feature.subtitle)
                    .padding(feature == context ? Spacing.xs : 0)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(feature == context ? BrandColor.primary.opacity(0.12) : .clear)
                    )
            }
        }
        .padding(Spacing.md)
        .glassCard(cornerRadius: Spacing.radiusMedium)
    }

    private func featureRow(icon: String, color: Color, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
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
            planCard(
                plan: .monthly,
                title: "Aylık Plan",
                price: monthlyDisplayPrice,
                period: "ay",
                badge: nil,
                subPrice: nil
            )
            planCard(
                plan: .yearly,
                title: "Yıllık Plan",
                price: yearlyDisplayPrice,
                period: "yıl",
                badge: yearlyDiscountBadge,
                subPrice: monthlyEquivalentFromYearly
            )
            planCard(
                plan: .lifetime,
                title: "Ömür Boyu",
                price: lifetimeDisplayPrice,
                period: nil,
                badge: LocaleHelper.string("Tek seferlik"),
                subPrice: "Bir kez öde, sonsuza kadar kullan"
            )
        }
    }

    private var monthlyDisplayPrice: String {
        subscriptionService.monthlyProduct.map { $0.displayPrice } ?? "$4.99"
    }

    private var yearlyDisplayPrice: String {
        subscriptionService.yearlyProduct.map { $0.displayPrice } ?? "$39.99"
    }

    private var lifetimeDisplayPrice: String {
        subscriptionService.lifetimeProduct.map { $0.displayPrice } ?? "$99.99"
    }

    /// Discount of yearly vs. 12× monthly, from the live storefront prices
    /// (TRY tiers differ from USD). Hidden when yearly isn't actually cheaper.
    private var yearlyDiscountBadge: String? {
        var percent = 33
        if let m = subscriptionService.monthlyProduct, let y = subscriptionService.yearlyProduct, m.price > 0 {
            let ratio = NSDecimalNumber(decimal: y.price / (m.price * 12)).doubleValue
            percent = Int(((1 - ratio) * 100).rounded())
        }
        guard percent > 0 else { return nil }
        return String(format: LocaleHelper.string("%%%lld İndirim"), percent)
    }

    private var selectedProduct: Product? {
        switch selectedPlan {
        case .monthly:  return subscriptionService.monthlyProduct
        case .yearly:   return subscriptionService.yearlyProduct
        case .lifetime: return subscriptionService.lifetimeProduct
        }
    }

    /// True only when the selected product has a free-trial intro offer AND
    /// this Apple ID is still eligible for it.
    private var trialAvailable: Bool {
        guard let id = selectedProduct?.id else { return false }
        return subscriptionService.trialEligibleProductIDs.contains(id)
    }

    private var monthlyEquivalentFromYearly: String {
        let perMonth = String(localized: "/ay")
        guard let p = subscriptionService.yearlyProduct else {
            return "$3.33\(perMonth)"
        }
        let monthly = p.price / 12
        return "\(monthly.formatted(p.priceFormatStyle))\(perMonth)"
    }

    private func planCard(
        plan: Plan,
        title: LocalizedStringKey,
        price: String,
        period: String?,
        badge: String?,
        subPrice: String?
    ) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            withAnimation(.spring(response: 0.3)) { selectedPlan = plan }
        } label: {
            HStack(spacing: Spacing.md) {
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
                                .background(plan == .lifetime ? BrandColor.primary : BrandColor.income)
                                .clipShape(Capsule())
                        }
                    }
                    if let sub = subPrice {
                        Text(LocalizedStringKey(sub))
                            .font(.brand(.caption))
                            .foregroundStyle(BrandColor.textTertiary)
                    }
                }

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.brand(.headline))
                        .foregroundStyle(isSelected ? BrandColor.primary : BrandColor.textPrimary)
                    if let period {
                        Text(LocalizedStringKey("/" + period))
                            .font(.brand(.caption))
                            .foregroundStyle(BrandColor.textTertiary)
                    }
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
                        ProgressView().tint(.white)
                    } else {
                        Text(ctaButtonTitle)
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

            // Pre-contract disclosure sits directly under the buy button
            // (TR Law 6502 + App Store 3.1.2): price, renewal, trial, how to cancel.
            Text(renewalNote)
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task {
                    do { try await subscriptionService.restorePurchases() }
                    catch { errorMessage = error.localizedDescription }
                }
            } label: {
                Text("Satın Alımları Geri Yükle")
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    private var ctaButtonTitle: LocalizedStringKey {
        if selectedPlan == .lifetime { return "Satın Al" }
        return trialAvailable ? "7 Gün Ücretsiz Dene" : "Abone Ol"
    }

    /// "₺149,99/ay" — the selected subscription's price with its billing period.
    private var selectedPriceWithPeriod: String {
        selectedPlan == .monthly
            ? monthlyDisplayPrice + LocaleHelper.string("/ay")
            : yearlyDisplayPrice + LocaleHelper.string("/yıl")
    }

    private var renewalNote: String {
        if selectedPlan == .lifetime {
            return LocaleHelper.string("Tek seferlik ödeme. Abonelik yok, yenileme yok.")
        }
        let terms = trialAvailable
            ? "7 gün ücretsiz. Deneme bitince abonelik %@ fiyatıyla başlar ve sen iptal edene kadar aynı fiyattan otomatik yenilenir. Ücret ödememek için deneme bitmeden en az 24 saat önce iptal et."
            : "Abonelik %@ fiyatıyla başlar ve sen iptal edene kadar aynı fiyattan otomatik yenilenir."
        return String(format: LocaleHelper.string(terms), selectedPriceWithPeriod)
            + " " + LocaleHelper.string("İstediğin zaman iptal edebilirsin: iPhone Ayarlar > adın > Abonelikler.")
    }

    // MARK: - Fine print

    private var finePrint: some View {
        // Turkish users get the Turkish legal pages.
        let suffix = LocaleHelper.isEnglish ? "" : "-tr"
        return HStack(spacing: Spacing.md) {
            Link("Gizlilik Politikası", destination: URL(string: "https://budgetella.app/privacy\(suffix)")!)
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.primary.opacity(0.7))
            Link("Kullanım Koşulları", destination: URL(string: "https://budgetella.app/terms\(suffix)")!)
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.primary.opacity(0.7))
        }
    }

    // MARK: - Purchase

    private func startPurchase() async {
        guard let product = selectedProduct else {
            errorMessage = String(localized: "Ürün yüklenemedi. Lütfen tekrar deneyin.")
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
