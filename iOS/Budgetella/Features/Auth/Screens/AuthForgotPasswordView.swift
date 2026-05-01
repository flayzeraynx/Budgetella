//
//  AuthForgotPasswordView.swift
//  Budgetella
//
//  Auth 05 · Şifreni mi unuttun — Email + reset link gönder + onay state
//

import SwiftUI

struct AuthForgotPasswordView: View {

    @Bindable var vm: AuthViewModel

    @State private var appeared = false
    @State private var sent = false

    var body: some View {
        VStack(spacing: 0) {
            backButton { vm.goBack() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 16)

            if sent {
                sentState
            } else {
                formState
            }

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: appeared)
        .onAppear { appeared = true }
    }

    // MARK: - Form state

    private var formState: some View {
        VStack(spacing: 0) {
            // Icon
            ZStack {
                Circle()
                    .fill(BrandColor.primary.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "key.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(BrandColor.primary)
            }
            .padding(.top, Spacing.xl)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Şifreni mi unuttun?")
                    .font(.brand(.largeTitle))
                    .foregroundStyle(BrandColor.textPrimary)
                Text("E-postana sıfırlama bağlantısı gönderelim.")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxl)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                fieldLabel("E-posta")
                AuthTextField(
                    icon: "envelope",
                    placeholder: "ozzy@budgetella.app",
                    text: $vm.email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    submitLabel: .done
                )
            }
            .padding(.horizontal, 28)

            if let error = vm.errorMessage {
                Text(error)
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.expense)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, Spacing.sm)
            }

            Button {
                Task {
                    let ok = await vm.sendPasswordReset()
                    if ok {
                        withAnimation(.spring(response: 0.4)) { sent = true }
                    }
                }
            } label: {
                if vm.isLoading {
                    ProgressView().tint(.white).frame(maxWidth: .infinity).frame(height: 56)
                        .background(LinearGradient(colors: [BrandColor.primary, BrandColor.primaryLight], startPoint: .leading, endPoint: .trailing))
                        .clipShape(Capsule())
                } else {
                    primaryButtonLabel("Sıfırlama linkini gönder")
                }
            }
            .disabled(vm.email.isEmpty)
            .opacity(vm.email.isEmpty ? 0.5 : 1)
            .padding(.horizontal, 28)
            .padding(.top, Spacing.xl)
        }
    }

    // MARK: - Sent confirmation state

    private var sentState: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(BrandColor.income.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(BrandColor.income)
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.top, Spacing.xxxl)

            VStack(spacing: Spacing.sm) {
                Text("Bağlantı gönderildi!")
                    .font(.brand(.title))
                    .foregroundStyle(BrandColor.textPrimary)
                Text("**\(vm.email)** adresine sıfırlama bağlantısı gönderdik. Gelen kutunu kontrol et.")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                vm.navigate(to: .signIn)
            } label: {
                primaryButtonLabel("Giriş ekranına dön")
            }
            .padding(.horizontal, 28)
            .padding(.top, Spacing.sm)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
