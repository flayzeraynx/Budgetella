//
//  OnboardingView.swift
//  Budgetella
//
//  4-adım onboarding container. TabView yerine manuel step geçişi —
//  tasarımdaki slide animasyonu için .transition(.asymmetric) kullanılıyor.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {

    @State private var vm = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()

            // Arka plan mor glow
            RadialGradient(
                colors: [BrandColor.primary.opacity(0.25), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            Group {
                switch vm.currentStep {
                case 0:
                    OnboardingWelcomeView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                case 1:
                    OnboardingFeaturesView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                case 2:
                    OnboardingCurrencyView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                case 3:
                    OnboardingPermissionsView(vm: vm) {
                        vm.complete(modelContext: modelContext, userId: "local")
                        onComplete()
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                default:
                    EmptyView()
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: vm.currentStep)
        }
        .preferredColorScheme(.dark)
    }
}
