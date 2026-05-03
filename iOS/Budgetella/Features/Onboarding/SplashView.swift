//
//  SplashView.swift
//  Budgetella
//

import SwiftUI

struct SplashView: View {

    var onComplete: () -> Void

    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var dotsVisible = false
    @State private var activeDot = 0

    private let dotTimer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Logo
                VStack(spacing: Spacing.md) {
                    ZStack {
                        // Glow ring
                        Circle()
                            .fill(BrandColor.primary.opacity(0.12))
                            .frame(width: 120, height: 120)
                        Circle()
                            .fill(BrandColor.primary.opacity(0.07))
                            .frame(width: 150, height: 150)

                        // Icon
                        BudgetellaLogoView(size: 80)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    VStack(spacing: 4) {
                        Text("Budgetella")
                            .font(.brand(.largeTitle))
                            .foregroundStyle(BrandColor.textPrimary)
                        Text("Finansal kontrol, her zaman")
                            .font(.brand(.footnote))
                            .foregroundStyle(BrandColor.textTertiary)
                    }
                    .opacity(titleOpacity)
                }

                Spacer()

                // Loading dots
                if dotsVisible {
                    HStack(spacing: 6) {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(i == activeDot ? BrandColor.primary : BrandColor.borderMedium)
                                .frame(width: 6, height: 6)
                                .animation(.spring(response: 0.3), value: activeDot)
                        }
                    }
                    .padding(.bottom, 48)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(dotTimer) { _ in
            activeDot = (activeDot + 1) % 3
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                titleOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.6)) {
                dotsVisible = true
            }
            // Auto-dismiss after 1.8s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                onComplete()
            }
        }
    }
}
