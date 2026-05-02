//
//  PaywallModalView.swift
//  Budgetella
//
//  Bottom-sheet paywall — feature lock ekranlarından çağrılır.
//  Tam ekran PaywallView'a geçiş butonu içerir.
//

import SwiftUI

struct PaywallModalView: View {

    let featureTitle: String
    let featureDescription: String
    let icon: String

    @Environment(\.dismiss) private var dismiss
    @State private var showFullPaywall = false

    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                // Drag indicator
                Capsule()
                    .fill(BrandColor.borderMedium)
                    .frame(width: 36, height: 4)
                    .padding(.top, Spacing.sm)

                // Icon
                ZStack {
                    Circle()
                        .fill(BrandColor.primary.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(BrandColor.primary)
                        .symbolRenderingMode(.hierarchical)
                }

                // Text
                VStack(spacing: Spacing.xs) {
                    Text(featureTitle)
                        .font(.brand(.title))
                        .foregroundStyle(BrandColor.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(featureDescription)
                        .font(.brand(.body))
                        .foregroundStyle(BrandColor.textTertiary)
                        .multilineTextAlignment(.center)
                }

                // Mini feature grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                    miniFeature(icon: "wand.and.sparkles", label: "AI Asistan")
                    miniFeature(icon: "camera.viewfinder", label: "Fiş OCR")
                    miniFeature(icon: "chart.bar.doc.horizontal", label: "Bütçe Takibi")
                    miniFeature(icon: "square.and.arrow.up", label: "Dışa Aktarma")
                }
                .padding(.horizontal, Spacing.sm)

                // CTA
                VStack(spacing: Spacing.sm) {
                    Button {
                        showFullPaywall = true
                    } label: {
                        Text("Premium'a Geç")
                            .font(.brand(.headline))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [BrandColor.primary, BrandColor.primaryLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
                            .shadow(color: BrandColor.primary.opacity(0.4), radius: 12, y: 4)
                    }

                    Button { dismiss() } label: {
                        Text("Şimdi değil")
                            .font(.brand(.body))
                            .foregroundStyle(BrandColor.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.xs)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
        }
        .fullScreenCover(isPresented: $showFullPaywall) {
            PaywallView()
        }
    }

    private func miniFeature(icon: String, label: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(BrandColor.primary)
            Text(label)
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textSecondary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: Spacing.radiusSmall)
    }
}
