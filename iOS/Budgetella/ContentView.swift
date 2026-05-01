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
    @Query private var settingsArr: [AppSettings]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("appTheme") private var appTheme = "system"
    @State private var appState: AppState = .splash

    private var biometricLockEnabled: Bool {
        settingsArr.first?.biometricLockEnabled ?? false
    }

    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "dark":  return .dark
        case "light": return .light
        default:      return nil
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
        .onAppear { BudgetellaApp.seedCategoriesIfNeeded(in: modelContext) }
        .onChange(of: isSignedIn) { _, newValue in
            if !newValue, appState == .main {
                withAnimation(.easeInOut(duration: 0.4)) {
                    appState = .auth
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
