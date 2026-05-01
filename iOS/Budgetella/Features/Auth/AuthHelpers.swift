//
//  AuthHelpers.swift
//  Budgetella
//
//  Auth ekranlarında ortak kullanılan view builder'lar.
//

import SwiftUI

// MARK: - Back Button

@ViewBuilder
func backButton(action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
            Text("Geri")
                .font(.brand(.subheadline))
        }
        .foregroundStyle(BrandColor.textSecondary)
        .frame(height: Spacing.minTouchTarget)
    }
    .buttonStyle(.plain)
}

// MARK: - Field Label

@ViewBuilder
func fieldLabel(_ title: String) -> some View {
    Text(title)
        .font(.brand(.footnote))
        .foregroundStyle(BrandColor.textTertiary)
}
