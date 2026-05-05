//
//  ContentView.swift
//  Budgetella
//
//  App router — splash → onboarding → auth → main tab sequence.
//  Her aşama tamamlandıkça AppState ilerler.
//

import SwiftUI
import SwiftData
@preconcurrency import FirebaseAuth

enum AppState {
    case splash
    case onboarding
    case auth
    case biometricLock
    case main
}

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settingsArr: [AppSettings]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isSignedIn") private var isSignedIn = false
    @State private var appState: AppState = .splash

    private var biometricLockEnabled: Bool {
        settingsArr.first?.biometricLockEnabled ?? false
    }

    private var colorScheme: ColorScheme? {
        // Default to dark before AppSettings is seeded to prevent light-mode flash
        guard let settings = settingsArr.first else { return .dark }
        switch settings.theme {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    var body: some View {
        Group {
            switch appState {
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        guard hasCompletedOnboarding else { appState = .onboarding; return }
                        // Firebase Auth SDK persists tokens in Keychain — check directly
                        if Auth.auth().currentUser != nil {
                            isSignedIn = true
                            appState = biometricLockEnabled ? .biometricLock : .main
                        } else {
                            appState = .auth
                        }
                    }
                }

            case .onboarding:
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appState = .auth
                    }
                }

            case .auth:
                AuthView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appState = .main
                    }
                }

            case .biometricLock:
                AuthFaceIDLockView(
                    onUnlocked: {
                        withAnimation(.easeInOut(duration: 0.35)) { appState = .main }
                    },
                    onSignOut: {
                        try? Auth.auth().signOut()
                        isSignedIn = false
                        UserDefaults.standard.set(false, forKey: "isSignedIn")
                        withAnimation(.easeInOut(duration: 0.35)) { appState = .auth }
                    }
                )

            case .main:
                MainTabView()
            }
        }
        .preferredColorScheme(colorScheme)
        .onAppear {
            BudgetellaApp.seedCategoriesIfNeeded(in: modelContext)
            BudgetellaApp.seedSettingsIfNeeded(in: modelContext)
            BudgetellaApp.migrateEnglishCategoryNames(in: modelContext)
            BudgetellaApp.migrateAddMissingCategories(in: modelContext)
            // Sync currency symbol to UserDefaults so Decimal formatters pick it up
            if let symbol = settingsArr.first?.currency.symbol {
                UserDefaults.standard.set(symbol, forKey: "selectedCurrencySymbol")
            }
            refreshWidget()
            // Re-register App Shortcuts after UI is ready (helps Siri indexing)
            BudgetellaShortcuts.updateAppShortcutParameters()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { refreshWidget() }
        }
        .onChange(of: isSignedIn) { _, newValue in
            if newValue, appState == .auth {
                // Only auto-navigate for providers that skip the in-app OTP flow
                // (Apple, Google). Email/password users have isEmailVerified = false
                // until they click the verification link — keep them in the auth flow.
                if Auth.auth().currentUser?.isEmailVerified == true {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appState = biometricLockEnabled ? .biometricLock : .main
                    }
                }
            }
            if !newValue, appState == .main {
                // Sign-out: remove FCM token from Firestore
                let uid = UserDefaults.standard.string(forKey: "currentUserId") ?? ""
                NotificationService.shared.removeToken(userId: uid)
                withAnimation(.easeInOut(duration: 0.4)) {
                    appState = .auth
                }
            }
        }
        // Push notification received → mirror to SwiftData
        .onReceive(NotificationCenter.default.publisher(for: .appPushReceived)) { note in
            guard let info = note.userInfo,
                  let title = info["title"] as? String,
                  let body  = info["body"]  as? String else { return }
            let kindRaw  = info["kind"]     as? String ?? NotificationKind.systemMessage.rawValue
            let deepLink = info["deepLink"] as? String
            let uid = UserDefaults.standard.string(forKey: "currentUserId") ?? "local"
            let record = NotificationRecord(
                userId: uid,
                kind: NotificationKind(rawValue: kindRaw) ?? .systemMessage,
                title: title,
                body: body,
                deepLink: deepLink
            )
            modelContext.insert(record)
            try? modelContext.save()
        }
        .environment(FirestoreService.shared)
        // Pre-warm iOS keyboard so first TextField focus is instant
        .background(KeyboardPrewarmView())
    }

    // MARK: - Widget

    private func refreshWidget() {
        let isPremium = UserDefaults.standard.bool(forKey: "budgetella.isPremium")
        WidgetDataManager.refresh(context: modelContext, isPremium: isPremium)
    }
}

// MARK: - Keyboard pre-warmer

private struct KeyboardPrewarmView: UIViewRepresentable {
    func makeUIView(context: Context) -> UITextField {
        let field = UITextField(frame: .zero)
        field.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            field.becomeFirstResponder()
            field.resignFirstResponder()
        }
        return field
    }
    func updateUIView(_ uiView: UITextField, context: Context) {}
}

#Preview {
    ContentView()
}
