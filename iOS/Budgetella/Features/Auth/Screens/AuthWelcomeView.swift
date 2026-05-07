//
//  AuthWelcomeView.swift
//  Budgetella
//
//  Auth 01 · Welcome — Apple / Google / E-posta seçenekleri
//

import SwiftUI

struct AuthWelcomeView: View {

    @Bindable var vm: AuthViewModel
    var onAuthComplete: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // ── Logo + App adı
            HStack(spacing: Spacing.sm) {
                appIcon
                Text("Budgetella")
                    .font(.brand(.headline))
                    .foregroundStyle(BrandColor.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)

            Spacer()

            // ── Hero
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Paranı yönet,\nbiraz da eğlen.")
                    .font(.brand(.largeTitle))
                    .foregroundStyle(BrandColor.textPrimary)

                Text("30 saniyede başla. Verilerin sadece sende — Apple/Google ile devam et veya e-posta gir.")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

            Spacer()

            // ── Auth buttons
            VStack(spacing: Spacing.sm) {
                // Apple
                Button {
                    vm.signInWithApple()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Apple ile devam et")
                            .font(.brand(.subheadline))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
                }

                // Google
                Button {
                    Task {
                        let ok = await vm.signInWithGoogle()
                        if ok { onAuthComplete() }
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        googleLogo
                        Text("Google ile devam et")
                            .font(.brand(.subheadline))
                    }
                    .foregroundStyle(BrandColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(BrandColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                            .strokeBorder(BrandColor.borderMedium, lineWidth: 1)
                    )
                }

                // Email
                Button {
                    vm.navigate(to: .signUp)
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "envelope")
                            .font(.system(size: 15, weight: .regular))
                        Text("E-posta ile devam et")
                            .font(.brand(.subheadline))
                    }
                    .foregroundStyle(BrandColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(BrandColor.surface.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                            .strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
                    )
                }

                // Giriş yap linki
                Button { vm.navigate(to: .signIn) } label: {
                    (Text("Hesabın var mı? ")
                        .foregroundStyle(BrandColor.textSecondary)
                     + Text("Giriş yap")
                        .foregroundStyle(BrandColor.textPrimary))
                        .font(.brand(.footnote))
                }
                .padding(.vertical, Spacing.sm)
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: appeared)

            // ── ToS caption with clickable links
            Text(tosAttributedString)
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
                .tint(BrandColor.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.top, Spacing.xs)
                .padding(.bottom, 36)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.4), value: appeared)
        }
        .onAppear { appeared = true }
    }

    // MARK: - ToS attributed string

    private var tosAttributedString: AttributedString {
        let prefix = AttributedString(String(localized: "Devam ederek "))

        var terms = AttributedString(String(localized: "Şartlar"))
        terms.link = URL(string: "https://budgetella.app/terms")
        terms.inlinePresentationIntent = .stronglyEmphasized

        let mid = AttributedString(String(localized: " ve "))

        var privacy = AttributedString(String(localized: "Gizlilik"))
        privacy.link = URL(string: "https://budgetella.app/privacy")
        privacy.inlinePresentationIntent = .stronglyEmphasized

        let suffix = AttributedString(String(localized: "'i kabul edersin."))

        return prefix + terms + mid + privacy + suffix
    }

    // MARK: - Sub-views

    private var appIcon: some View {
        BudgetellaLogoView(size: 36)
    }

    private var googleLogo: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
            Text("G")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(hex: "#4285F4"))
        }
    }
}
