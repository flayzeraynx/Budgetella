//
//  OnboardingPermissionsView.swift
//  Budgetella
//
//  Adım 04 · İzinler
//

import SwiftUI

struct OnboardingPermissionsView: View {

    var vm: OnboardingViewModel
    var onComplete: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            stepHeader(current: 4, total: 4, onSkip: onComplete)
                .padding(.horizontal, 28)
                .padding(.top, 16)

            Spacer()

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Birkaç izin verir misin?")
                    .font(.brand(.largeTitle))
                    .foregroundStyle(BrandColor.textPrimary)
                Text("Her şey cihazında kalır. Her zaman.")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.bottom, Spacing.xl)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

            VStack(spacing: Spacing.sm) {
                permissionRow(
                    icon: "mic.fill",
                    title: "Mikrofon",
                    description: "Sesli işlem girişi için: \"100 lira benzin\".",
                    isEnabled: vm.microphoneEnabled,
                    delay: 0.18
                ) {
                    Task { await vm.requestMicrophone() }
                }

                permissionRow(
                    icon: "camera.fill",
                    title: "Kamera",
                    description: "Fiş fotoğrafı çekip anında işlem oluştur.",
                    isEnabled: vm.cameraEnabled,
                    delay: 0.25
                ) {
                    Task { await vm.requestCamera() }
                }

                permissionRow(
                    icon: "bell.fill",
                    title: "Bildirimler",
                    description: "Fatura hatırlatmaları ve tasarruf önerileri.",
                    isEnabled: vm.notificationsEnabled,
                    delay: 0.32
                ) {
                    Task { await vm.requestNotifications() }
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            Button(action: onComplete) {
                primaryButtonLabel("Takibe Başla")
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut.delay(0.5), value: appeared)
        }
        .onAppear { appeared = true }
    }

    private func permissionRow(
        icon: String,
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        isEnabled: Bool,
        delay: Double,
        onToggle: @escaping () -> Void
    ) -> some View {
        HStack(spacing: Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous)
                    .fill(BrandColor.primary.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(BrandColor.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.brand(.subheadline))
                    .foregroundStyle(BrandColor.textPrimary)
                Text(description)
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textTertiary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in onToggle() }
            ))
            .tint(BrandColor.primary)
            .labelsHidden()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .glassCard(cornerRadius: Spacing.radiusMedium)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: appeared)
    }
}
