//
//  SettingsView.swift
//  Budgetella
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    @Query private var settingsArr: [AppSettings]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currentUserId") private var currentUserId = ""
    @AppStorage("displayName") private var displayName = ""
    @AppStorage("userEmail") private var userEmail = ""

    @State private var authService = AuthService()
    @State private var subscriptionService = SubscriptionService()

    @State private var showProfile = false
    @State private var showSubscription = false
    @State private var showPaywall = false
    @State private var showThemePicker = false
    @State private var showLanguagePicker = false
    @State private var showCurrencyPicker = false
    @State private var showDeleteConfirm = false
    @State private var showSignOutConfirm = false

    private var settings: AppSettings? { settingsArr.first }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                List {
                    // Profile card
                    Section {
                        profileCard
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))

                    // Premium
                    Section {
                        premiumRow
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.4))
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

                    // App preferences
                    Section("Tercihler") {
                        settingsRow(
                            icon: "paintbrush",
                            iconColor: BrandColor.primary,
                            title: "Tema",
                            value: themeLabel(settings?.theme ?? .system)
                        ) { showThemePicker = true }

                        settingsRow(
                            icon: "globe",
                            iconColor: BrandColor.info,
                            title: "Dil",
                            value: settings?.language.displayName ?? "Türkçe"
                        ) { showLanguagePicker = true }

                        settingsRow(
                            icon: "dollarsign.circle",
                            iconColor: BrandColor.income,
                            title: "Para Birimi",
                            value: (settings?.currency.symbol ?? "₺") + " " + (settings?.currency.rawValue ?? "TRY")
                        ) { showCurrencyPicker = true }
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.4))

                    // Security
                    Section("Güvenlik") {
                        if let s = settings {
                            HStack {
                                settingsIconBadge(icon: "faceid", color: .green)
                                Text("Face ID / Touch ID")
                                    .font(.brand(.body))
                                    .foregroundStyle(BrandColor.textPrimary)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { s.biometricLockEnabled },
                                    set: {
                                        s.biometricLockEnabled = $0
                                        s.updatedAt = .now
                                    }
                                ))
                                .tint(BrandColor.primary)
                                .labelsHidden()
                            }
                            .padding(.vertical, 2)

                            HStack {
                                settingsIconBadge(icon: "eye.slash", color: BrandColor.warning)
                                Text("Tutarları Gizle")
                                    .font(.brand(.body))
                                    .foregroundStyle(BrandColor.textPrimary)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { s.hideAmounts },
                                    set: {
                                        s.hideAmounts = $0
                                        s.updatedAt = .now
                                    }
                                ))
                                .tint(BrandColor.primary)
                                .labelsHidden()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.4))

                    // Data
                    Section("Veriler") {
                        settingsRow(
                            icon: "square.and.arrow.up",
                            iconColor: BrandColor.primaryLight,
                            title: "Dışa Aktar",
                            value: nil
                        ) { }

                        settingsRow(
                            icon: "square.and.arrow.down",
                            iconColor: BrandColor.primaryLight,
                            title: "Yedeği İçe Aktar",
                            value: nil
                        ) { }
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.4))

                    // Support
                    Section("Destek") {
                        settingsRow(icon: "questionmark.circle", iconColor: BrandColor.info,
                                    title: "Yardım & Destek", value: nil) { }
                        settingsRow(icon: "lock.shield", iconColor: BrandColor.textTertiary,
                                    title: "Gizlilik Politikası", value: nil) { }
                        settingsRow(icon: "doc.text", iconColor: BrandColor.textTertiary,
                                    title: "Kullanım Koşulları", value: nil) { }
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.4))

                    // Account
                    Section("Hesap") {
                        Button {
                            showSignOutConfirm = true
                        } label: {
                            HStack(spacing: Spacing.md) {
                                settingsIconBadge(icon: "rectangle.portrait.and.arrow.right", color: BrandColor.warning)
                                Text("Çıkış Yap")
                                    .font(.brand(.body))
                                    .foregroundStyle(BrandColor.warning)
                            }
                        }
                        .listRowBackground(BrandColor.surface.opacity(0.4))

                        Button {
                            showDeleteConfirm = true
                        } label: {
                            HStack(spacing: Spacing.md) {
                                settingsIconBadge(icon: "trash", color: BrandColor.expense)
                                Text("Hesabı Sil")
                                    .font(.brand(.body))
                                    .foregroundStyle(BrandColor.expense)
                            }
                        }
                        .listRowBackground(BrandColor.surface.opacity(0.4))
                    }

                    // App version
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 2) {
                                Text("Budgetella")
                                    .font(.brand(.caption))
                                    .foregroundStyle(BrandColor.textTertiary)
                                Text("v\(appVersion)")
                                    .font(.brand(.caption))
                                    .foregroundStyle(BrandColor.textTertiary.opacity(0.6))
                            }
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .preferredColorScheme(.dark)
            // Sheets
            .sheet(isPresented: $showProfile) {
                ProfileView(authService: authService)
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView(subscriptionService: subscriptionService)
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showThemePicker) {
                ThemePickerSheet(settings: settings)
            }
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerSheet(settings: settings)
            }
            .sheet(isPresented: $showCurrencyPicker) {
                CurrencyPickerSheet(settings: settings)
            }
            .confirmationDialog("Çıkış yap?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Çıkış Yap", role: .destructive) {
                    try? authService.signOut(modelContext: modelContext)
                }
                Button("Vazgeç", role: .cancel) {}
            }
            .confirmationDialog("Hesabı sil?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Hesabı Sil", role: .destructive) {
                    Task { try? await authService.deleteAccount(modelContext: modelContext) }
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Tüm verileriniz kalıcı olarak silinecek. Bu işlem geri alınamaz.")
            }
        }
        .task { await subscriptionService.setup() }
    }

    // MARK: - Profile card

    private var profileCard: some View {
        Button { showProfile = true } label: {
            HStack(spacing: Spacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [BrandColor.primary, BrandColor.primaryLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    Text(String(displayName.prefix(1)).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName.isEmpty ? "Profil" : displayName)
                        .font(.brand(.headline))
                        .foregroundStyle(BrandColor.textPrimary)
                    Text(userEmail.isEmpty ? "E-posta yükleniyor..." : userEmail)
                        .font(.brand(.footnote))
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

    // MARK: - Premium row

    private var premiumRow: some View {
        Button {
            if subscriptionService.isPremium {
                showSubscription = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: Spacing.md) {
                settingsIconBadge(icon: "sparkles", color: BrandColor.primary)

                if subscriptionService.isPremium {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Budgetella Premium")
                            .font(.brand(.body))
                            .foregroundStyle(BrandColor.textPrimary)
                        Text("Aktif abonelik")
                            .font(.brand(.caption))
                            .foregroundStyle(BrandColor.income)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Premium'a Geç")
                            .font(.brand(.body))
                            .foregroundStyle(BrandColor.primary)
                        Text("7 gün ücretsiz dene")
                            .font(.brand(.caption))
                            .foregroundStyle(BrandColor.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Row helpers

    private func settingsRow(
        icon: String,
        iconColor: Color,
        title: String,
        value: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                settingsIconBadge(icon: icon, color: iconColor)
                Text(title)
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textPrimary)
                Spacer()
                if let val = value {
                    Text(val)
                        .font(.brand(.footnote))
                        .foregroundStyle(BrandColor.textTertiary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BrandColor.textTertiary.opacity(0.5))
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    private func settingsIconBadge(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(color.opacity(0.15))
                .frame(width: 30, height: 30)
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
        }
    }

    private func themeLabel(_ theme: AppTheme) -> String {
        switch theme {
        case .dark: return "Koyu"
        case .light: return "Açık"
        case .system: return "Sistem"
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
