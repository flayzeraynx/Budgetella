//
//  AuthSignInView.swift
//  Budgetella
//
//  Auth 03 · Tekrar hoş geldin — Email + Şifre + Face ID quick action
//

import SwiftUI

struct AuthSignInView: View {

    @Bindable var vm: AuthViewModel
    var onAuthComplete: () -> Void

    @State private var appeared = false
    private let biometricEnabled = KeychainHelper.bool(for: .biometricEnabled)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                backButton { vm.goBack() }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Tekrar hoş geldin")
                        .font(.brand(.largeTitle))
                        .foregroundStyle(BrandColor.textPrimary)
                    Text("Şifrenle gir veya Face ID kullan.")
                        .font(.brand(.body))
                        .foregroundStyle(BrandColor.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.xxl)

                VStack(spacing: Spacing.md) {
                    // E-posta
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        fieldLabel("E-posta")
                        AuthTextField(
                            icon: "envelope",
                            placeholder: "ozzy@budgetella.app",
                            text: $vm.email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            submitLabel: .next
                        )
                    }

                    // Şifre
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            fieldLabel("Şifre")
                            Spacer()
                            Button("Şifremi unuttum") {
                                vm.navigate(to: .forgotPassword)
                            }
                            .font(.brand(.footnote))
                            .foregroundStyle(BrandColor.primary)
                        }
                        AuthTextField(
                            icon: "lock",
                            placeholder: "••••••••••",
                            text: $vm.password,
                            isSecure: true,
                            textContentType: .password,
                            submitLabel: .done
                        )
                    }
                }
                .padding(.horizontal, 28)

                // Hata mesajı
                if let error = vm.errorMessage {
                    Text(error)
                        .font(.brand(.footnote))
                        .foregroundStyle(BrandColor.expense)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                        .padding(.top, Spacing.sm)
                }

                // Giriş yap CTA
                Button {
                    Task {
                        let ok = await vm.signIn()
                        if ok { onAuthComplete() }
                    }
                } label: {
                    if vm.isLoading {
                        ProgressView().tint(.white).frame(maxWidth: .infinity).frame(height: 56)
                            .background(LinearGradient(colors: [BrandColor.primary, BrandColor.primaryLight], startPoint: .leading, endPoint: .trailing))
                            .clipShape(Capsule())
                    } else {
                        primaryButtonLabel("Giriş yap")
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, Spacing.xl)

                // Face ID row (kayıtlıysa göster)
                if biometricEnabled {
                    Button {
                        Task {
                            let ok = await vm.enableFaceID()
                            if ok { onAuthComplete() }
                        }
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "faceid")
                                .font(.system(size: 22))
                                .foregroundStyle(BrandColor.primary)
                                .frame(width: 40, height: 40)
                                .background(BrandColor.primary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Face ID ile gir")
                                    .font(.brand(.subheadline))
                                    .foregroundStyle(BrandColor.textPrimary)
                                Text("Bir kere bak, içeri gir.")
                                    .font(.brand(.footnote))
                                    .foregroundStyle(BrandColor.textTertiary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(BrandColor.textTertiary)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .glassCard(cornerRadius: Spacing.radiusMedium)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 28)
                    .padding(.top, Spacing.sm)
                }

                // Kaydol linki
                Button { vm.navigate(to: .signUp) } label: {
                    (Text("Hesabın yok mu? ")
                        .foregroundStyle(BrandColor.textSecondary)
                     + Text("Kaydol")
                        .foregroundStyle(BrandColor.textPrimary))
                        .font(.brand(.footnote))
                }
                .padding(.top, Spacing.xl)
                .padding(.bottom, 48)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: appeared)
        .onAppear { appeared = true }
    }
}
