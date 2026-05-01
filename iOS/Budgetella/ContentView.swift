//
//  ContentView.swift
//  Budgetella
//
//  App router — onboarding → auth → main tab sequence.
//  Her aşama tamamlandıkça AppState ilerler.
//

import SwiftUI

enum AppState {
    case onboarding
    case auth         // #5 — Auth flow (gelecek)
    case main         // #6+ — Dashboard + tabs (gelecek)
}

struct ContentView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var appState: AppState = .onboarding

    var body: some View {
        Group {
            switch appState {
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
        .onAppear {
            if hasCompletedOnboarding {
                appState = .auth
            }
        }
    }

    @ViewBuilder
    private func placeholderScreen(title: String, subtitle: String) -> some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(BrandColor.primary)
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(.brand(.title))
                    .foregroundStyle(BrandColor.textPrimary)
                Text(subtitle)
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textTertiary)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
