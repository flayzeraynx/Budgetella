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
    var termsAccepted = false

    // MARK: - UI State
    var isLoading = false
    var errorMessage: String?
    var otpCountdown = 60
    var otpResendEnabled = false
    private var countdownTask: Task<Void, Never>?

    // MARK: - Auth Service
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Navigation

    func navigate(to screen: AuthScreen) {
        if screen == .signIn {
            email = ""
            password = ""
            errorMessage = nil
        }
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
            errorMessage = String(localized: "Devam etmek için kullanım şartlarını kabul et.")
            return false
        }
        guard PasswordStrength.evaluate(password).score >= 2 else {
            errorMessage = String(localized: "Daha güçlü bir şifre seç.")
            return false
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.signUp(email: email, password: password, displayName: name)
            try? await authService.sendEmailVerification()
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
            // GIDSignInError.canceled == -5 — user dismissed the sheet, no toast needed
            let ns = error as NSError
            if ns.domain == "com.google.GIDSignIn" && ns.code == -5 { return false }
            errorMessage = friendlyError(error)
            return false
        }
    }

    // MARK: - Email Verification

    func verifyOTP() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let verified = try await authService.reloadAndCheckVerified()
            if verified {
                return true
            } else {
                errorMessage = String(localized: "E-posta henüz doğrulanmadı. Mailine gelen linke tıkla, sonra tekrar dene.")
                return false
            }
        } catch {
            errorMessage = friendlyError(error)
            return false
        }
    }

    func resendOTP() {
        guard otpResendEnabled else { return }
        otpResendEnabled = false
        startOTPCountdown()
        Task { try? await authService.sendEmailVerification() }
    }

    private func startOTPCountdown() {
        otpCountdown = 60
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
            errorMessage = String(localized: "E-posta adresini gir.")
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
            errorMessage = String(localized: "Face ID bu cihazda kullanılamıyor.")
            return false
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: String(localized: "Budgetella'ya hızlı girmek için Face ID'yi etkinleştir")
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
        if msg.contains("email-already-in-use") { return String(localized: "Bu e-posta zaten kayıtlı.") }
        if msg.contains("wrong-password")       { return String(localized: "E-posta veya şifre hatalı.") }
        if msg.contains("invalid-credential")   { return String(localized: "Oturum süresi dolmuş. Lütfen tekrar giriş yap.") }
        if msg.contains("user-not-found")       { return String(localized: "Bu e-postayla kayıtlı hesap bulunamadı.") }
        if msg.contains("network")              { return String(localized: "İnternet bağlantını kontrol et.") }
        return msg
    }
}
