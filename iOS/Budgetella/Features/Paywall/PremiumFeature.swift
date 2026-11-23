//
//  PremiumFeature.swift
//  Budgetella
//
//  Single source of truth for what Premium unlocks. The paywall benefit list is
//  rendered from this enum, so it cannot advertise something that isn't locked.
//  Everything not listed here is free (manual entry, budgets, stats, rule-based Budgi insight card, import, export…).
//

import SwiftUI

enum PremiumFeature: String, CaseIterable, Identifiable {
    case budgi, receiptScan, customCategories, widget

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .budgi:            return "wand.and.sparkles"
        case .receiptScan:      return "camera.viewfinder"
        case .customCategories: return "square.grid.2x2"
        case .widget:           return "rectangle.3.group"
        }
    }

    var color: Color {
        switch self {
        case .budgi:            return BrandColor.primary
        case .receiptScan:      return BrandColor.info
        case .customCategories: return BrandColor.income
        case .widget:           return BrandColor.expense
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .budgi:            return "Budgi AI Asistan"
        case .receiptScan:      return "Fiş Tarama"
        case .customCategories: return "Özel Kategoriler"
        case .widget:           return "Ana Ekran Widget'ı"
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .budgi:            return "Harcamaların hakkında soru sor, öneri al"
        case .receiptScan:      return "Kamerayla otomatik fiş kaydı"
        case .customCategories: return "Kendi kategorilerini oluştur"
        case .widget:           return "Günlük özetin ana ekranında"
        }
    }
}

// MARK: - Lock marker

/// Small "Premium" pill shown on locked entry points so a gate reads as
/// intentional rather than broken.
struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "lock.fill")
                .font(.system(size: 8, weight: .bold))
            Text("Premium")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(BrandColor.primary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(BrandColor.primary.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Premium özellik"))
    }
}

// MARK: - Proactive paywall

/// Identifiable payload for `.fullScreenCover(item:)`.
struct PaywallRequest: Identifiable {
    let id = UUID()
    var context: PremiumFeature?
}

/// The paywall is offered unprompted at most twice in the app's lifetime:
/// once after onboarding, once after the 10th saved transaction.
enum PaywallPrompt {
    case afterOnboarding, afterTenthTransaction

    static let shownAfterOnboardingKey = "paywall.shownAfterOnboarding"
    static let shownAfterTenTxKey      = "paywall.shownAfterTenTx"
    static let savedTxCountKey         = "paywall.savedTxCount"
    static let transactionThreshold    = 10

    /// Pure decision — which proactive paywall (if any) is due right now.
    static func next(
        isPremium: Bool,
        onboardingDone: Bool,
        shownOnboarding: Bool,
        txCount: Int,
        shownAt10: Bool
    ) -> PaywallPrompt? {
        guard !isPremium, onboardingDone else { return nil }
        if !shownOnboarding { return .afterOnboarding }
        if txCount >= transactionThreshold, !shownAt10 { return .afterTenthTransaction }
        return nil
    }

    var flagKey: String {
        switch self {
        case .afterOnboarding:       return Self.shownAfterOnboardingKey
        case .afterTenthTransaction: return Self.shownAfterTenTxKey
        }
    }

    #if DEBUG
    static func selfCheck() {
        func n(_ p: Bool, _ o: Bool, _ so: Bool, _ tx: Int, _ s10: Bool) -> PaywallPrompt? {
            next(isPremium: p, onboardingDone: o, shownOnboarding: so, txCount: tx, shownAt10: s10)
        }
        assert(n(true,  true,  false, 50, false) == nil, "premium users are never prompted")
        assert(n(false, false, false, 50, false) == nil, "nothing before onboarding is done")
        assert(n(false, true,  false, 0,  false) == .afterOnboarding)
        assert(n(false, true,  false, 50, false) == .afterOnboarding, "one prompt at a time")
        assert(n(false, true,  true,  9,  false) == nil)
        assert(n(false, true,  true,  10, false) == .afterTenthTransaction)
        assert(n(false, true,  true,  10, true)  == nil, "each prompt fires once")
    }
    #endif
}
