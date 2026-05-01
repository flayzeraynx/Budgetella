//
//  OnboardingPermissionsView.swift
//  Budgetella
//
//  Adım 04 · İzinler
//  Mikrofon + Kamera + Bildirimler — iOS native permission dialog tetikler.
//  "Everything stays on-device. Always."
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
                Text("Allow a few things?")
                    .font(.brand(.largeTitle))
                    .foregroundStyle(BrandColor.textPrimary)
                Text("Everything stays on-device. Always.")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.bottom, Spacing.xl)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

            // ── Permission rows
            VStack(spacing: Spacing.sm) {
                permissionRow(
                    icon: "mic.fill",
                    title: "Microphone",
                    description: "For voice entry: \"100 lira gas\".",
                    isEnabled: vm.microphoneEnabled,
                    delay: 0.18
                ) {
                    Task { await vm.requestMicrophone() }
                }

                permissionRow(
                    icon: "camera.fill",
                    title: "Camera",
                    description: "Snap receipts to log instantly.",
                    isEnabled: vm.cameraEnabled,
                    delay: 0.25
                ) {
                    Task { await vm.requestCamera() }
                }

                permissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Bill reminders & saving nudges.",
                    isEnabled: vm.notificationsEnabled,
                    delay: 0.32
                ) {
                    Task { await vm.requestNotifications() }
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            Button(action: onComplete) {
                primaryButtonLabel("Start tracking")
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
        title: String,
        description: String,
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

#Preview {
    ZStack {
        BrandColor.background.ignoresSafeArea()
        OnboardingPermissionsView(vm: OnboardingViewModel(), onComplete: {})
    }
    .preferredColorScheme(.dark)
}
