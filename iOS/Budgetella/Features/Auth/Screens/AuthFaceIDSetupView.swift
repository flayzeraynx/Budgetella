//
//  AuthFaceIDSetupView.swift
//  Budgetella
//
//  Auth 06 · Face ID kurulumu — Glow icon + 3 fayda chip + etkinleştir CTA
//

import SwiftUI

struct AuthFaceIDSetupView: View {

    @Bindable var vm: AuthViewModel
    var onComplete: () -> Void

    @State private var appeared = false
    @State private var glowPulse = false

    var body: some View {
        VStack(spacing: 0) {
            backButton { vm.goBack() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 16)

            Spacer()

            // Face ID glow icon
            ZStack {
                Circle()
                    .fill(BrandColor.primary.opacity(0.08))
                    .frame(width: 140, height: 140)
                    .scaleEffect(glowPulse ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulse)

                Circle()
                    .fill(BrandColor.primary.opacity(0.15))
                    .frame(width: 110, height: 110)

                Image(systemName: "faceid")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(BrandColor.primary)
                    .symbolRenderingMode(.hierarchical)
            }
            .onAppear { glowPulse = true }
            .padding(.bottom, Spacing.xxl)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Face ID ile hızlı giriş")
                    .font(.brand(.largeTitle))
                    .foregroundStyle(BrandColor.textPrimary)
                Text("Bir kez bak, bütçeni aç. Şifre yazma dönemi bitti.")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.bottom, Spacing.xl)

            // Feature chips
            VStack(spacing: Spacing.sm) {
                featureChip(
                    icon: "bolt.fill",
                    color: BrandColor.primary,
                    title: "Anında erişim",
                    subtitle: "Uygulama açılır açılmaz içeri gir"
                )
                featureChip(
                    icon: "lock.shield.fill",
                    color: BrandColor.income,
                    title: "Verillerin güvende",
                    subtitle: "Biyometrik veriler sadece cihazında kalır"
                )
                featureChip(
                    icon: "arrow.clockwise",
                    color: BrandColor.primaryLight,
                    title: "İstediğinde kapat",
                    subtitle: "Ayarlardan her zaman devre dışı bırakabilirsin"
                )
            }
            .padding(.horizontal, 28)

            Spacer()

            VStack(spacing: Spacing.md) {
                Button {
                    Task {
                        let ok = await vm.enableFaceID()
                        if ok { onComplete() }
                    }
                } label: {
                    if vm.isLoading {
                        ProgressView().tint(.white).frame(maxWidth: .infinity).frame(height: 56)
                            .background(LinearGradient(colors: [BrandColor.primary, BrandColor.primaryLight], startPoint: .leading, endPoint: .trailing))
                            .clipShape(Capsule())
                    } else {
                        primaryButtonLabel("Face ID'yi etkinleştir")
                    }
                }

                Button {
                    onComplete()
                } label: {
                    Text("Şimdilik geç")
                        .font(.brand(.footnote))
                        .foregroundStyle(BrandColor.textTertiary)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: appeared)
        .onAppear { appeared = true }
    }

    private func featureChip(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.brand(.subheadline))
                    .foregroundStyle(BrandColor.textPrimary)
                Text(subtitle)
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textTertiary)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .glassCard(cornerRadius: Spacing.radiusMedium)
    }
}
