//
//  AuthFaceIDLockView.swift
//  Budgetella
//
//  Auth 07 · Face ID kilidi — Uygulama kilitliyken gösterilir.
//  "Şifre kullan" fallback + "Hesaptan çık" aksiyonu.
//

import SwiftUI
import LocalAuthentication

struct AuthFaceIDLockView: View {

    var onUnlocked: () -> Void
    var onSignOut: () -> Void

    @State private var appeared = false
    @State private var glowPulse = false
    @State private var scanning = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App icon
                BudgetellaLogoView(size: 72)
                    .padding(.bottom, Spacing.xl)

                Text("Budgetella")
                    .font(.brand(.title))
                    .foregroundStyle(BrandColor.textPrimary)

                Text("Kimliğini doğrula")
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textTertiary)
                    .padding(.top, Spacing.xs)
                    .padding(.bottom, Spacing.xxl)

                // Face ID glow button
                Button {
                    triggerFaceID()
                } label: {
                    ZStack {
                        Circle()
                            .fill(BrandColor.primary.opacity(0.08))
                            .frame(width: 120, height: 120)
                            .scaleEffect(glowPulse ? 1.12 : 1.0)
                            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: glowPulse)

                        Circle()
                            .fill(BrandColor.primary.opacity(0.15))
                            .frame(width: 96, height: 96)

                        Image(systemName: scanning ? "faceid" : "faceid")
                            .font(.system(size: 46, weight: .light))
                            .foregroundStyle(BrandColor.primary)
                            .symbolEffect(.pulse, isActive: scanning)
                    }
                }
                .buttonStyle(.plain)
                .onAppear {
                    glowPulse = true
                    triggerFaceID()
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.brand(.footnote))
                        .foregroundStyle(BrandColor.expense)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, Spacing.lg)
                        .transition(.opacity)
                }

                Spacer()

                // Actions
                VStack(spacing: Spacing.sm) {
                    Button {
                        triggerPasscode()
                    } label: {
                        primaryButtonLabel("Şifre kullan")
                    }

                    Button {
                        withAnimation { errorMessage = nil }
                        onSignOut()
                    } label: {
                        Text("Hesaptan çık")
                            .font(.brand(.footnote))
                            .foregroundStyle(BrandColor.expense)
                    }
                    .padding(.bottom, Spacing.lg)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3), value: appeared)
        .onAppear { appeared = true }
    }

    private func triggerPasscode() {
        scanning = true
        errorMessage = nil
        Task {
            do {
                let ctx = LAContext()
                let success = try await ctx.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: "Budgetella'ya girmek için kimliğini doğrula"
                )
                scanning = false
                if success { onUnlocked() }
            } catch {
                scanning = false
                withAnimation { errorMessage = "Kimlik doğrulanamadı. Tekrar dene." }
            }
        }
    }

    private func triggerFaceID() {
        scanning = true
        errorMessage = nil
        Task {
            do {
                let ctx = LAContext()
                var authError: NSError?
                guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
                    scanning = false
                    let code = (authError as? LAError)?.code
                    if code == .biometryLockout {
                        // Biometri kilitli — şifre fallback'e yönlendir
                        withAnimation { errorMessage = "Yüz tanıma kilitlendi. Şifre kullanın." }
                        triggerPasscode()
                    } else {
                        withAnimation { errorMessage = "Biyometrik doğrulama kullanılamıyor. Şifre kullanın." }
                    }
                    return
                }
                let success = try await ctx.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "Budgetella'ya girmek için kimliğini doğrula"
                )
                scanning = false
                if success { onUnlocked() }
            } catch let error as LAError {
                scanning = false
                withAnimation {
                    if error.code == .biometryLockout {
                        errorMessage = "Yüz tanıma kilitlendi. Şifre kullanın."
                        triggerPasscode()
                    } else {
                        errorMessage = "Kimlik doğrulanamadı. Tekrar dene."
                    }
                }
            } catch {
                scanning = false
                withAnimation { errorMessage = "Kimlik doğrulanamadı. Tekrar dene." }
            }
        }
    }
}
