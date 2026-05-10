//
//  SettingsView.swift
//  Budgetella
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @Query private var settingsArr: [AppSettings]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currentUserId") private var currentUserId = ""
    @AppStorage("displayName") private var displayName = ""
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("userPhotoURL") private var userPhotoURL = ""

    @State private var authService = AuthService()
    @State private var subscriptionService = SubscriptionService()

    @State private var showProfile = false
    @State private var showSubscription = false
    @State private var showPaywall = false
    @State private var showThemePicker = false
    @State private var showLanguagePicker = false
    @State private var showCurrencyPicker = false
    @State private var showSignOutConfirm = false
    @State private var showImportPicker = false
    @State private var showImportResult = false
    @State private var importResultMessage = ""
    @State private var isImporting = false
    @State private var isExporting = false

    private var settings: AppSettings? { settingsArr.first }

    private var preferredScheme: ColorScheme? {
        switch settings?.theme ?? .system {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

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
                            value: settings?.language.displayName ?? AppLanguage.english.displayName
                        ) { showLanguagePicker = true }

                        settingsRow(
                            icon: "dollarsign.circle",
                            iconColor: BrandColor.income,
                            title: "Para Birimi",
                            value: "\(settings?.currency.symbol ?? "₺") \(settings?.currency.rawValue ?? "TRY")"
                        ) { showCurrencyPicker = true }
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.4))

                    // Security
                    Section("Güvenlik") {
                        if let s = settings {
                            Button {
                                s.biometricLockEnabled.toggle()
                                s.updatedAt = .now
                            } label: {
                                HStack {
                                    settingsIconBadge(icon: "faceid", color: .green)
                                    Text("Face ID / Touch ID")
                                        .font(.brand(.body))
                                        .foregroundStyle(BrandColor.textPrimary)
                                    Spacer()
                                    Toggle("", isOn: .constant(s.biometricLockEnabled))
                                        .tint(BrandColor.primary)
                                        .labelsHidden()
                                        .allowsHitTesting(false)
                                }
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.listRow)
                            .listRowInsets(EdgeInsets())

                            Button {
                                s.hideAmounts.toggle()
                                s.updatedAt = .now
                            } label: {
                                HStack {
                                    settingsIconBadge(icon: "eye.slash", color: BrandColor.warning)
                                    Text("Tutarları Gizle")
                                        .font(.brand(.body))
                                        .foregroundStyle(BrandColor.textPrimary)
                                    Spacer()
                                    Toggle("", isOn: .constant(s.hideAmounts))
                                        .tint(BrandColor.primary)
                                        .labelsHidden()
                                        .allowsHitTesting(false)
                                }
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.listRow)
                            .listRowInsets(EdgeInsets())
                        }
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.4))

                    // Data
                    Section("Veriler") {
                        settingsRow(
                            icon: isExporting ? "arrow.triangle.2.circlepath" : "square.and.arrow.up",
                            iconColor: BrandColor.primaryLight,
                            title: "Dışa Aktar",
                            value: nil,
                            disabled: isExporting
                        ) {
                            guard !isExporting else { return }
                            isExporting = true
                            Task { @MainActor in
                                defer { isExporting = false }
                                guard let url = try? BackupExportService.export(from: modelContext) else { return }
                                // Present UIActivityViewController from the topmost VC so it
                                // works correctly even when SettingsView is inside a sheet.
                                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                      let rootVC = scene.keyWindow?.rootViewController else { return }
                                var topVC = rootVC
                                while let presented = topVC.presentedViewController { topVC = presented }
                                let shareVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                                topVC.present(shareVC, animated: true)
                            }
                        }

                        settingsRow(
                            icon: isImporting ? "arrow.triangle.2.circlepath" : "square.and.arrow.down",
                            iconColor: BrandColor.primaryLight,
                            title: importRowTitle,
                            value: nil,
                            disabled: isImporting
                        ) {
                            guard !isImporting else { return }
                            showImportPicker = true
                        }


                    }
                    .listRowBackground(BrandColor.surface.opacity(0.4))

                    // Notifications
                    Section("Bildirimler") {
                        NavigationLink {
                            NotificationSettingsView()
                        } label: {
                            HStack(spacing: Spacing.md) {
                                settingsIconBadge(icon: "bell.fill", color: BrandColor.primary)
                                Text("Bildirim Yönetimi")
                                    .font(.brand(.body))
                                    .foregroundStyle(BrandColor.textPrimary)
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                        .listRowInsets(EdgeInsets())
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.4))

                    // Categories
                    Section("Kategoriler") {
                        NavigationLink {
                            CategoryManagementView()
                        } label: {
                            HStack(spacing: Spacing.md) {
                                settingsIconBadge(icon: "tag.fill", color: BrandColor.primaryLight)
                                Text("Kategori Yönetimi")
                                    .font(.brand(.body))
                                    .foregroundStyle(BrandColor.textPrimary)
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                        .listRowInsets(EdgeInsets())
                    }
                    .listRowBackground(BrandColor.surface.opacity(0.4))

                    // Support
                    Section("Destek") {
                        settingsRow(icon: "questionmark.circle", iconColor: BrandColor.info,
                                    title: "Yardım & Destek", value: nil) {
                            if let url = URL(string: "mailto:support@budgetella.app") {
                                UIApplication.shared.open(url)
                            }
                        }
                        settingsRow(icon: "lock.shield", iconColor: BrandColor.textTertiary,
                                    title: "Gizlilik Politikası", value: nil) {
                            if let url = URL(string: "https://budgetella.app/privacy") {
                                UIApplication.shared.open(url)
                            }
                        }
                        settingsRow(icon: "doc.text", iconColor: BrandColor.textTertiary,
                                    title: "Kullanım Koşulları", value: nil) {
                            if let url = URL(string: "https://budgetella.app/terms") {
                                UIApplication.shared.open(url)
                            }
                        }
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
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.listRow)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(BrandColor.surface.opacity(0.4))

                        NavigationLink {
                            DeleteAccountView(authService: authService)
                        } label: {
                            HStack(spacing: Spacing.md) {
                                settingsIconBadge(icon: "trash", color: BrandColor.expense)
                                Text("Hesabı Sil")
                                    .font(.brand(.body))
                                    .foregroundStyle(BrandColor.expense)
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                        .listRowInsets(EdgeInsets())
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
                // Note: we deliberately leave UIScrollView.delaysContentTouches at the
                // system default (true). Setting it to false makes Button-backed rows
                // eat vertical drags, so the user can't scroll the list by dragging on
                // a row — only by dragging in the gaps between sections. The tiny
                // first-tap delay is the right trade-off here.
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BrandColor.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(BrandColor.surface.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
            }
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
        }
        .preferredColorScheme(preferredScheme)
        .task { await subscriptionService.setup(userId: currentUserId) }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            isImporting = true
            let userId = currentUserId.isEmpty ? "local" : currentUserId
            Task { @MainActor in
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                do {
                    let res = try BackupImportService.importFromURL(url, modelContext: modelContext, userId: userId)
                    importResultMessage = String(format: String(localized: "%d işlem aktarıldı.\n%d tekrar atlandı."), res.imported, res.skipped)
                    if res.categoriesCreated > 0 {
                        importResultMessage += String(format: String(localized: "\n%d yeni kategori oluşturuldu."), res.categoriesCreated)
                    }
                    isImporting = false
                    showImportResult = true
                    if !currentUserId.isEmpty {
                        let allTxs = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
                        FirestoreService.shared.batchUploadTransactions(allTxs)
                    }
                } catch {
                    importResultMessage = "Hata: \(error.localizedDescription)"
                    isImporting = false
                    showImportResult = true
                }
            }
        }
        .brandAlert(
            title: "İçe Aktarma Tamamlandı",
            dynamicMessage: importResultMessage,
            isPresented: $showImportResult,
            buttons: [.cancel("Tamam")]
        )
        .brandAlert(
            title: "Çıkış Yap",
            message: "Hesabınızdan çıkış yapılacak.",
            isPresented: $showSignOutConfirm,
            buttons: [
                .destructive("Çıkış Yap") { try? authService.signOut(modelContext: modelContext) },
                .cancel()
            ]
        )
    }

    // MARK: - Profile card

    private var initialsCircle: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [BrandColor.primary, BrandColor.primaryLight],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 52, height: 52)
            Text(String(displayName.prefix(1)).uppercased())
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var profileCard: some View {
        Button { showProfile = true } label: {
            HStack(spacing: Spacing.md) {
                // Avatar
                Group {
                    if let url = URL(string: userPhotoURL), !userPhotoURL.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                                    .frame(width: 52, height: 52)
                                    .clipShape(Circle())
                            default:
                                initialsCircle
                            }
                        }
                    } else {
                        initialsCircle
                    }
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
        .buttonStyle(.card(cornerRadius: Spacing.radiusMedium))
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
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.listRow)
        .listRowInsets(EdgeInsets())
    }

    // MARK: - Row helpers

    private func settingsRow(
        icon: String,
        iconColor: Color,
        title: LocalizedStringKey,
        value: String?,
        disabled: Bool = false,
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
                if !disabled {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BrandColor.textTertiary.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.listRow)
        .listRowInsets(EdgeInsets())
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
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

    private func themeDisplayName(_ theme: AppTheme) -> LocalizedStringKey {
        switch theme {
        case .dark:   return "Karanlık"
        case .light:  return "Açık"
        case .system: return "Sistem"
        }
    }

    private func themeLabel(_ theme: AppTheme) -> String {
        switch theme {
        case .dark:   return LocaleHelper.string("Karanlık")
        case .light:  return LocaleHelper.string("Açık")
        case .system: return LocaleHelper.string("Sistem")
        }
    }

    private var importRowTitle: LocalizedStringKey {
        isImporting ? "İçe aktarılıyor…" : "Yedeği İçe Aktar"
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
