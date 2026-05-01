//
//  ContentView.swift
//  Budgetella
//
//  App router — splash → onboarding → auth → main tab sequence.
//  Her aşama tamamlandıkça AppState ilerler.
//

import SwiftUI

enum AppState {
    case splash
    case onboarding
    case auth
    case main
}

struct ContentView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var appState: AppState = .splash

    var body: some View {
        Group {
            switch appState {
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        appState = hasCompletedOnboarding ? .auth : .onboarding
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

            case .main:
                MainTabView()
            }
        }
    }
}

#Preview {
    ContentView()
}
