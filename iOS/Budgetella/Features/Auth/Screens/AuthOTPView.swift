//
//  AuthOTPView.swift
//  Budgetella
//
//  Auth 04 · E-postanı doğrula — Firebase link verification
//

import SwiftUI

struct AuthOTPView: View {

    @Bindable var vm: AuthViewModel
    let email: String
    var onVerified: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            backButton { vm.goBack() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 16)

            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(BrandColor.primary.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(BrandColor.primary)
            }
            .padding(.bottom, Spacing.xl)

            // Title + subtitle
            VStack(spacing: Spacing.sm) {
                Text("E-postanı doğrula")
                    .font(.brand(.largeTitle))
                    .foregroundStyle(BrandColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text("**\(email)**\nadresine bir doğrulama linki gönderdik.\nLinke tıkla, sonra aşağıdaki butona bas.")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)

                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 12))
                    Text("Spam / Junk klasörünü de kontrol et")
                        .font(.brand(.caption))
                }
                .foregroundStyle(BrandColor.textTertiary.opacity(0.7))
                .padding(.top, Spacing.xs)
            }
            .padding(.horizontal, 36)

            // Hata
            if let error = vm.errorMessage {
                Text(error)
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.expense)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, Spacing.lg)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()

            // Yeniden gönder
            Button {
                vm.resendOTP()
            } label: {
                Group {
                    if vm.otpResendEnabled {
                        (Text("Link gelmedi mi? ")
                            .foregroundStyle(BrandColor.textSecondary)
                         + Text("Tekrar gönder")
                            .foregroundStyle(BrandColor.primary))
                    } else {
                        (Text("Link gelmedi mi? ")
                            .foregroundStyle(BrandColor.textTertiary)
                         + Text("Tekrar gönder (\(formattedCountdown))")
                            .foregroundStyle(BrandColor.textTertiary))
                    }
                }
                .font(.brand(.footnote))
            }
            .disabled(!vm.otpResendEnabled)
            .padding(.bottom, Spacing.lg)

            // CTA
            Button {
                Task {
                    let ok = await vm.verifyOTP()
                    if ok { onVerified() }
                }
            } label: {
                if vm.isLoading {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(LinearGradient(colors: [BrandColor.primary, BrandColor.primaryLight],
                                                   startPoint: .leading, endPoint: .trailing))
                        .clipShape(Capsule())
                } else {
                    primaryButtonLabel("Doğrulamayı kontrol et")
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
        }
        .animation(.spring(response: 0.3), value: vm.errorMessage)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: appeared)
        .onAppear { appeared = true }
    }

    private var formattedCountdown: String {
        let m = vm.otpCountdown / 60
        let s = vm.otpCountdown % 60
        return m > 0 ? "\(m):\(String(format: "%02d", s))" : "0:\(String(format: "%02d", s))"
    }
}
