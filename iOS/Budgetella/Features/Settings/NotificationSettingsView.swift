//
//  NotificationSettingsView.swift
//  Budgetella
//

import SwiftUI

struct NotificationSettingsView: View {

    @AppStorage("notifAllEnabled")         private var allEnabled = true
    @AppStorage("notifWeeklyDigest")       private var weeklyDigest = true
    @AppStorage("notifAnomalyAlerts")      private var anomalyAlerts = true
    @AppStorage("notifSavingsSuggestions") private var savingsSuggestions = true

    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()

            List {
                // Master toggle
                Section {
                    toggleRow(
                        icon: "bell.fill",
                        iconColor: BrandColor.primary,
                        title: "Tüm Bildirimler",
                        subtitle: "Tüm bildirimleri aç veya kapat",
                        binding: $allEnabled
                    )
                } footer: {
                    Text("Kapatıldığında hiçbir bildirim gönderilmez.")
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.textTertiary)
                }
                .listRowBackground(BrandColor.surface.opacity(0.4))

                // Individual toggles
                Section("BİLDİRİM TÜRLERİ") {
                    toggleRow(
                        icon: "chart.bar.doc.horizontal",
                        iconColor: BrandColor.info,
                        title: "Haftalık Özet",
                        subtitle: "Her Pazartesi harcama özeti",
                        binding: Binding(
                            get: { weeklyDigest && allEnabled },
                            set: { weeklyDigest = $0 }
                        )
                    )
                    .disabled(!allEnabled)

                    toggleRow(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: BrandColor.warning,
                        title: "Anomali Uyarıları",
                        subtitle: "Alışılmadık harcama tespit edilince",
                        binding: Binding(
                            get: { anomalyAlerts && allEnabled },
                            set: { anomalyAlerts = $0 }
                        )
                    )
                    .disabled(!allEnabled)

                    toggleRow(
                        icon: "lightbulb.fill",
                        iconColor: BrandColor.income,
                        title: "Tasarruf Önerileri",
                        subtitle: "AI tabanlı kişisel öneriler",
                        binding: Binding(
                            get: { savingsSuggestions && allEnabled },
                            set: { savingsSuggestions = $0 }
                        )
                    )
                    .disabled(!allEnabled)
                }
                .listRowBackground(BrandColor.surface.opacity(0.4))
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Bildirimler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BrandColor.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func toggleRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        binding: Binding<Bool>
    ) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
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

            Toggle("", isOn: binding)
                .tint(BrandColor.primary)
                .labelsHidden()
        }
        .padding(.vertical, 2)
    }
}
