//
//  AuthOTPView.swift
//  Budgetella
//
//  Auth 04 · E-postanı doğrula — 6 haneli OTP + auto-fill hint + countdown
//

import SwiftUI

struct AuthOTPView: View {

    @Bindable var vm: AuthViewModel
    let email: String
    var onVerified: () -> Void

    @State private var appeared = false
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 0) {
            backButton { vm.goBack() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("E-postanı doğrula")
                    .font(.brand(.largeTitle))
                    .foregroundStyle(BrandColor.textPrimary)
                Text("6 haneli kodu **\(email)**'ye gönderdik. Birazdan gelir.")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxl)

            // OTP boxes
            OTPFieldView(code: $vm.otpCode)
                .padding(.horizontal, 28)

            // Auto-fill hint (kod 4+ hane girilince göster)
            if vm.otpCode.count >= 4 {
                autoFillHint
                    .padding(.horizontal, 28)
                    .padding(.top, Spacing.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Hata
            if let error = vm.errorMessage {
                Text(error)
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.expense)
                    .padding(.horizontal, 28)
                    .padding(.top, Spacing.sm)
            }

            Spacer()

            // Yeniden gönder
            Button {
                vm.resendOTP()
            } label: {
                if vm.otpResendEnabled {
                    (Text("Kod gelmedi mi? ")
                        .foregroundStyle(BrandColor.textSecondary)
                     + Text("Tekrar gönder")
                        .foregroundStyle(BrandColor.primary))
                        .font(.brand(.footnote))
                } else {
                    (Text("Kod gelmedi mi? ")
                        .foregroundStyle(BrandColor.textTertiary)
                     + Text("Tekrar gönder (\(formattedCountdown))")
                        .foregroundStyle(BrandColor.textTertiary))
                        .font(.brand(.footnote))
                }
            }
            .disabled(!vm.otpResendEnabled)
            .padding(.bottom, Spacing.lg)

            // Doğrula CTA
            Button {
                Task {
                    let ok = await vm.verifyOTP()
                    if ok { onVerified() }
                }
            } label: {
                if vm.isLoading {
                    ProgressView().tint(.white).frame(maxWidth: .infinity).frame(height: 56)
                        .background(LinearGradient(colors: [BrandColor.primary, BrandColor.primaryLight], startPoint: .leading, endPoint: .trailing))
                        .clipShape(Capsule())
                } else {
                    primaryButtonLabel("Doğrula ve devam et")
                }
            }
            .disabled(vm.otpCode.count < 6)
            .opacity(vm.otpCode.count < 6 ? 0.5 : 1)
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
        }
        .animation(.spring(response: 0.3), value: vm.otpCode.count)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: appeared)
        .onAppear { appeared = true }
    }

    private var autoFillHint: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(BrandColor.income)
                .font(.system(size: 16))
            Text("Klavyeden **\"\(vm.otpCode)\"**yi otomatik dolduralım")
                .font(.brand(.footnote))
                .foregroundStyle(BrandColor.textSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous)
                .fill(BrandColor.income.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous)
                        .strokeBorder(BrandColor.income.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var formattedCountdown: String {
        let m = vm.otpCountdown / 60
        let s = vm.otpCountdown % 60
        return m > 0 ? "\(m):\(String(format: "%02d", s))" : "0:\(String(format: "%02d", s))"
    }
}
