//
//  SubscriptionView.swift
//  Budgetella
//
//  Settings → Aboneliğim. Active plan details + management.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {

    var subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var isRestoring = false
    @State private var restoreError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {

                        // Status card
                        statusCard
                            .padding(.top, Spacing.sm)

                        // Actions
                        VStack(spacing: Spacing.sm) {
                            // Manage subscription (Apple deep link)
                            actionButton(
                                icon: "gear",
                                title: "Aboneliği Yönet",
                                subtitle: "App Store üzerinden düzenle",
                                color: BrandColor.primary
                            ) {
                                UIApplication.shared.open(subscriptionService.managementURL)
                            }

                            // Restore purchases
                            actionButton(
                                icon: "arrow.clockwise",
                                title: "Satın Alımları Geri Yükle",
                                subtitle: "Önceki aboneliğini geri yükle",
                                color: BrandColor.info
                            ) {
                                Task { await restore() }
                            }
                        }

                        if let err = restoreError {
                            Text(err)
                                .font(.brand(.footnote))
                                .foregroundStyle(BrandColor.expense)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        // Legal links
                        HStack(spacing: Spacing.lg) {
                            Link("Gizlilik Politikası",
                                 destination: URL(string: "https://budgetella.app/privacy")!)
                            Link("Kullanım Koşulları",
                                 destination: URL(string: "https://budgetella.app/terms")!)
                        }
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.primary.opacity(0.7))
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Aboneliğim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(BrandColor.primary)
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Status card

    private var statusCard: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                ZStack {
                    Circle()
                        .fill(BrandColor.primary.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(BrandColor.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Budgetella Premium")
                        .font(.brand(.headline))
                        .foregroundStyle(BrandColor.textPrimary)
                    HStack(spacing: 4) {
                        Circle().fill(BrandColor.income).frame(width: 6, height: 6)
                        Text("Aktif")
                            .font(.brand(.footnote))
                            .foregroundStyle(BrandColor.income)
                    }
                }
                Spacer()
            }

            Divider().background(BrandColor.borderSubtle)

            HStack {
                statColumn(label: "Plan", value: activePlanLabel)
                Spacer()
                statColumn(label: "Durum", value: "Aktif")
            }
        }
        .padding(Spacing.lg)
        .glassCard(cornerRadius: Spacing.radiusMedium)
    }

    private var activePlanLabel: String {
        if subscriptionService.monthlyProduct != nil {
            return "Aylık"
        } else if subscriptionService.yearlyProduct != nil {
            return "Yıllık"
        }
        return "Premium"
    }

    private func statColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
            Text(value)
                .font(.brand(.subheadline))
                .foregroundStyle(BrandColor.textPrimary)
        }
    }

    // MARK: - Action button

    private func actionButton(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.brand(.body))
                        .foregroundStyle(BrandColor.textPrimary)
                    Text(subtitle)
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .padding(Spacing.md)
            .glassCard(cornerRadius: Spacing.radiusMedium)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func restore() async {
        isRestoring = true
        restoreError = nil
        do {
            try await subscriptionService.restorePurchases()
        } catch {
            restoreError = error.localizedDescription
        }
        isRestoring = false
    }
}
