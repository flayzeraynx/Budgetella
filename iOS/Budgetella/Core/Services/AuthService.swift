//
//  AuthService.swift
//  Budgetella
//
//  Firebase Auth wrapper. Webapp AuthContext.tsx'ten Swift'e port.
//  @MainActor @Observable — SwiftUI view'lardan doğrudan bind edilebilir.
//
//  Auth flow:
//  1. Email/Password signup + login
//  2. Sign in with Apple (ASAuthorizationController + Firebase credential)
//  3. Google Sign-In (GoogleSignIn SDK + Firebase credential)
//  4. Sign out → lokal transaction/category temizle, AppSettings koru
//  5. Şifre reset / güncelleme (reauthenticate önce)
//  6. Hesap silme (Firestore doc sil + FirebaseAuth delete)
//

import Foundation
import SwiftUI
import SwiftData
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFirestore
@preconcurrency import GoogleSignIn
import AuthenticationServices
import CryptoKit

@MainActor
@Observable
public final class AuthService: NSObject {

    // MARK: - Published State

    public var currentUser: FirebaseAuth.User?
    public var isLoading = false
    public var errorMessage: String?

    // MARK: - Private
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    // MARK: - Init / Deinit

    public override init() {
        super.init()
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                if let user {
                    KeychainHelper.set(user.uid, for: .firebaseUid)
                    UserDefaults.standard.set(user.displayName ?? "", forKey: "displayName")
                    UserDefaults.standard.set(user.email ?? "", forKey: "userEmail")
                    UserDefaults.standard.set(user.uid, forKey: "currentUserId")
                    UserDefaults.standard.set(user.photoURL?.absoluteString ?? "", forKey: "userPhotoURL")
                    UserDefaults.standard.set(true, forKey: "isSignedIn")
                } else {
                    KeychainHelper.delete(.firebaseUid)
                    UserDefaults.standard.set("", forKey: "displayName")
                    UserDefaults.standard.set("", forKey: "userEmail")
                    UserDefaults.standard.set("", forKey: "currentUserId")
                    UserDefaults.standard.set(false, forKey: "isSignedIn")
                }
            }
        }
    }

    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Convenience

    public var isSignedIn: Bool { currentUser != nil }
    public var uid: String? { currentUser?.uid }
    public var displayName: String? { currentUser?.displayName }
    public var email: String? { currentUser?.email }

    /// True only when the user has an email/password provider (not Apple/Google SSO).
    /// Use this to show/hide the Change Password option in settings.
    public var isEmailProvider: Bool {
        currentUser?.providerData.contains(where: { $0.providerID == "password" }) ?? false
    }

    // MARK: - Email / Password

    public func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
    }

    public func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    public func sendPasswordReset(to email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    public func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.sendEmailVerification()
    }

    /// Kullanıcıyı Firebase'den yeniden yükler ve e-posta doğrulama durumunu döner.
    public func reloadAndCheckVerified() async throws -> Bool {
        guard let user = Auth.auth().currentUser else { return false }
        try await user.reload()
        return user.isEmailVerified
    }

    /// Mevcut şifreyi reauthenticate edip yenisini set eder.
    public func updatePassword(current: String, new: String) async throws {
        guard let user = currentUser, let email = user.email else {
            throw AuthError.noUser
        }
        isLoading = true
        defer { isLoading = false }
        let credential = EmailAuthProvider.credential(withEmail: email, password: current)
        try await user.reauthenticate(with: credential)
        try await user.updatePassword(to: new)
    }

    public func updateDisplayName(_ name: String) async throws {
        guard let user = currentUser else { throw AuthError.noUser }
        let request = user.createProfileChangeRequest()
        request.displayName = name
        try await request.commitChanges()
    }

    // MARK: - Sign in with Apple

    /// Apple login flow başlatır. ASAuthorizationController callback'i bu class'a gelir.
    public func signInWithApple() {
        let nonce = randomNonce()
        currentNonce = nonce
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Google Sign-In

    public func signInWithGoogle() async throws {
        guard let rootVC = rootViewController() else {
            throw AuthError.noRootViewController
        }
        isLoading = true
        defer { isLoading = false }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.googleTokenMissing
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        try await Auth.auth().signIn(with: credential)
    }

    // MARK: - Sign Out

    /// İşlem ve kategorileri temizler, AppSettings'i korur (webapp AuthContext pattern'i).
    public func signOut(modelContext: ModelContext) throws {
        try Auth.auth().signOut()
        clearLocalData(modelContext: modelContext)
        KeychainHelper.delete(.firebaseIdToken)
    }

    // MARK: - Delete Account

    public func deleteAccount(modelContext: ModelContext) async throws {
        guard let user = currentUser else { throw AuthError.noUser }
        let uid = user.uid
        isLoading = true
        defer { isLoading = false }
        // Firestore cleanup best-effort while still authenticated
        try? await Firestore.firestore().collection("users").document(uid).delete()
        clearLocalData(modelContext: modelContext)
        // Auth deletion is the definitive step — errors propagate to caller
        try await user.delete()
        KeychainHelper.clearAll()
    }

    // MARK: - Private Helpers

    private func clearLocalData(modelContext: ModelContext) {
        try? modelContext.delete(model: Transaction.self)
        try? modelContext.delete(model: Category.self)
        try? modelContext.delete(model: SubscriptionRecord.self)
        try? modelContext.delete(model: Achievement.self)
        try? modelContext.delete(model: Goal.self)
        try? modelContext.delete(model: Budget.self)
        try? modelContext.delete(model: NotificationRecord.self)
        try? modelContext.delete(model: User.self)
    }

    /// Reauthenticate the current user with their email/password before a sensitive operation.
    public func reauthenticate(password: String) async throws {
        guard let user = currentUser, let email = user.email else {
            throw AuthError.noUser
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
    }

    @MainActor
    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
    }

    private func randomNonce(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    public nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else { return }

        Task { @MainActor in
            guard let nonce = self.currentNonce else { return }
            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: nonce,
                fullName: credential.fullName
            )
            do {
                try await Auth.auth().signIn(with: firebaseCredential)
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    public nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            self.isLoading = false
            if (error as? ASAuthorizationError)?.code != .canceled {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    public nonisolated func presentationAnchor(
        for controller: ASAuthorizationController
    ) -> ASPresentationAnchor {
        // presentationAnchor her zaman main thread'de çağrılır — assumeIsolated güvenli.
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first ?? ASPresentationAnchor()
        }
    }
}

// MARK: - Error

public enum AuthError: LocalizedError {
    case noUser
    case noRootViewController
    case googleTokenMissing

    public var errorDescription: String? {
        switch self {
        case .noUser:               return String(localized: "Kullanıcı oturumu bulunamadı.")
        case .noRootViewController: return String(localized: "Uygulama arayüzü hazır değil.")
        case .googleTokenMissing:   return String(localized: "Google giriş token'ı alınamadı.")
        }
    }
}
