//
//  OnboardingHelpers.swift
//  Budgetella
//
//  Onboarding ekranlarında ortak kullanılan view builder'lar.
//  Global scope'da free functions — import gerektirmez.
//

import SwiftUI

// MARK: - Step Header

/// "2 / 4  ··········  Skip" üst bar
@ViewBuilder
func stepHeader(current: Int, total: Int, onSkip: @escaping () -> Void) -> some View {
    HStack {
        Text("\(current) / \(total)")
            .font(.brand(.footnote))
            .foregroundStyle(BrandColor.textTertiary)

        Spacer()

        Button("Geç", action: onSkip)
            .font(.brand(.footnote))
            .foregroundStyle(BrandColor.textSecondary)
    }
    .padding(.vertical, Spacing.sm)
}

// MARK: - Primary Button

/// Tam genişlik, accent gradient, capsule CTA
@ViewBuilder
func primaryButtonLabel(_ title: String) -> some View {
    Text(title)
        .font(.brand(.subheadline))
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
        .shadow(color: BrandColor.primary.opacity(0.4), radius: 16, y: 6)
}
