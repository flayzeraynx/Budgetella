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
    nonisolated(unsafe) private var authStateListener: AuthStateDidChangeListenerHandle?
    nonisolated(unsafe) private var currentNonce: String?

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
        isLoading = true
        defer { isLoading = false }
        try await Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .delete()
        clearLocalData(modelContext: modelContext)
        try await user.delete()
        KeychainHelper.clearAll()
    }

    // MARK: - Private Helpers

    private func clearLocalData(modelContext: ModelContext) {
        try? modelContext.delete(model: Transaction.self)
        try? modelContext.delete(model: Category.self)
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
              let idToken = String(data: tokenData, encoding: .utf8),
              let nonce = currentNonce else { return }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        Task { @MainActor in
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
        case .noUser:               return "Kullanıcı oturumu bulunamadı."
        case .noRootViewController: return "Uygulama arayüzü hazır değil."
        case .googleTokenMissing:   return "Google giriş token'ı alınamadı."
        }
    }
}
