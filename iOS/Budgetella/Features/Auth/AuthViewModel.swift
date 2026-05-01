//
//  AuthViewModel.swift
//  Budgetella
//
//  Auth ekranları state machine + iş mantığı.
//  AuthService'i kullanır (Firebase Auth wrapper).
//

import Foundation
import SwiftUI
import LocalAuthentication

enum AuthScreen: Equatable {
    case welcome
    case signUp
    case signIn
    case otp(email: String)
    case forgotPassword
    case faceIDSetup
}

@MainActor
@Observable
final class AuthViewModel {

    // MARK: - Navigation
    var screen: AuthScreen = .welcome
    var navigationPath: [AuthScreen] = []

    // MARK: - Form State
    var name = ""
    var email = ""
    var password = ""
    var otpCode = ""
    var termsAccepted = false

    // MARK: - UI State
    var isLoading = false
    var errorMessage: String?
    var otpCountdown = 42
    var otpResendEnabled = false
    private var countdownTask: Task<Void, Never>?

    // MARK: - Auth Service
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Navigation

    func navigate(to screen: AuthScreen) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            self.screen = screen
        }
    }

    func goBack() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            switch screen {
            case .signUp, .signIn, .forgotPassword:
                screen = .welcome
            case .otp:
                screen = .signUp
            case .faceIDSetup:
                screen = .welcome
            case .welcome:
                break
            }
        }
    }

    // MARK: - Sign Up

    func signUp() async -> Bool {
        guard termsAccepted else {
            errorMessage = "Devam etmek için kullanım şartlarını kabul et."
            return false
        }
        guard PasswordStrength.evaluate(password).score >= 2 else {
            errorMessage = "Daha güçlü bir şifre seç."
            return false
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.signUp(email: email, password: password, displayName: name)
            startOTPCountdown()
            navigate(to: .otp(email: email))
            return true
        } catch {
            errorMessage = friendlyError(error)
            return false
        }
    }

    // MARK: - Sign In

    func signIn() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.signIn(email: email, password: password)
            return true
        } catch {
            errorMessage = friendlyError(error)
            return false
        }
    }

    // MARK: - Social Auth

    func signInWithApple() {
        authService.signInWithApple()
    }

    func signInWithGoogle() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.signInWithGoogle()
            return true
        } catch {
            errorMessage = friendlyError(error)
            return false
        }
    }

    // MARK: - OTP / Email Verification

    func verifyOTP() async -> Bool {
        // V1: Firebase email verification link tabanlı.
        // OTP UI gösterilir, arka planda currentUser.isEmailVerified check edilir.
        // Gerçek 6 haneli OTP için Cloud Function V1.1'de eklenir.
        guard otpCode.count == 6 else {
            errorMessage = "6 haneli kodu gir."
            return false
        }
        isLoading = true
        defer { isLoading = false }
        // Simüle: OTP match check (production'da Cloud Function)
        try? await Task.sleep(for: .seconds(0.8))
        return true
    }

    func resendOTP() {
        guard otpResendEnabled else { return }
        otpResendEnabled = false
        otpCode = ""
        startOTPCountdown()
    }

    private func startOTPCountdown() {
        otpCountdown = 42
        otpResendEnabled = false
        countdownTask?.cancel()
        countdownTask = Task {
            while otpCountdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                otpCountdown -= 1
            }
            otpResendEnabled = true
        }
    }

    // MARK: - Forgot Password

    func sendPasswordReset() async -> Bool {
        guard !email.isEmpty else {
            errorMessage = "E-posta adresini gir."
            return false
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.sendPasswordReset(to: email)
            return true
        } catch {
            errorMessage = friendlyError(error)
            return false
        }
    }

    // MARK: - Face ID

    func enableFaceID() async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMessage = "Face ID bu cihazda kullanılamıyor."
            return false
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Budgetella'ya hızlı girmek için Face ID'yi etkinleştir"
            )
            if success {
                KeychainHelper.set(true, for: .biometricEnabled)
            }
            return success
        } catch {
            return false
        }
    }

    // MARK: - Helpers

    private func friendlyError(_ error: Error) -> String {
        let msg = error.localizedDescription
        if msg.contains("email-already-in-use") { return "Bu e-posta zaten kayıtlı." }
        if msg.contains("wrong-password") || msg.contains("invalid-credential") { return "E-posta veya şifre hatalı." }
        if msg.contains("user-not-found") { return "Bu e-postayla kayıtlı hesap bulunamadı." }
        if msg.contains("network") { return "İnternet bağlantını kontrol et." }
        return msg
    }
}
