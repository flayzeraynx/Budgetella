//
//  BudgetellaApp.swift
//  Budgetella
//
//  App entry point — SwiftData ModelContainer + Firebase init.
//  IAP: native StoreKit 2 (Transaction.currentEntitlements).
//  Auth gating, onboarding ve feature routing ContentView downstream'de.
//

import SwiftUI
import SwiftData
import AppIntents
@preconcurrency import FirebaseCore

@main
struct BudgetellaApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer

    init() {
        // First-launch language default: English for everyone, regardless of system locale.
        // Users can switch to Turkish (or any supported language) later from Settings → Dil.
        // Uses a dedicated key so this only fires once and doesn't fight a user's later choice.
        if !UserDefaults.standard.bool(forKey: "defaultLanguageApplied") {
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
            UserDefaults.standard.set(true, forKey: "defaultLanguageApplied")
            UserDefaults.standard.synchronize()
        }

        // Firebase — GoogleService-Info.plist'ten otomatik konfigürasyon
        FirebaseApp.configure()

        // Notification delegates — UNUserNotificationCenter + FCM
        NotificationService.shared.configure()

        // Siri App Shortcuts — register phrases with the system
        BudgetellaShortcuts.updateAppShortcutParameters()

        // SwiftData ModelContainer
        // Declared outside do-catch so both the try and the recovery path share the same schema/config
        let schema = Schema([
            Transaction.self,
            Category.self,
            User.self,
            AppSettings.self,
            Achievement.self,
            Budget.self,
            Goal.self,
            NotificationRecord.self,
            SubscriptionRecord.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // V1: pure local; iCloud sync premium V1.1+
        )
        do {
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            // Migration or store corruption — wipe and recreate once rather than hard-crash
            let fm = FileManager.default
            if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeFiles = (try? fm.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil)) ?? []
                // Target only SwiftData's default store files — leave Firestore cache intact
                storeFiles
                    .filter { $0.lastPathComponent.hasPrefix("default.store") }
                    .forEach { try? fm.removeItem(at: $0) }
            }
            UserDefaults.standard.set(true, forKey: "storeWipedOnLaunch")
            do {
                self.modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("SwiftData failed after store reset: \(error)")
            }
        }
    }

    @State private var appReloadToken = UUID()
    @State private var appLocale: Locale = {
        let raw = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first
                  ?? Locale.current.language.languageCode?.identifier
                  ?? "en"
        return Locale(identifier: String(raw.prefix(2)))
    }()
    @State private var isReloadingForLanguage = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .id(appReloadToken)
                    .environment(\.locale, appLocale)

                if isReloadingForLanguage {
                    LanguageSwitchSkeletonView()
                        .transition(.opacity)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
                // Pop the skeleton up first so the user sees the transition,
                // then swap locale + force a tree rebuild via id token, then fade it out.
                withAnimation(.easeOut(duration: 0.18)) {
                    isReloadingForLanguage = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    let raw = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first
                              ?? Locale.current.language.languageCode?.identifier
                              ?? "en"
                    appLocale = Locale(identifier: String(raw.prefix(2)))
                    appReloadToken = UUID()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                    withAnimation(.easeIn(duration: 0.22)) {
                        isReloadingForLanguage = false
                    }
                }
            }
        }
        .modelContainer(modelContainer)
        .backgroundTask(.appRefresh("seed")) { }
    }
}

// MARK: - Language switch skeleton
//
// Brief shimmer overlay shown while the SwiftUI tree rebuilds after a language change.
// Mirrors the layout language of the app (header bar, list rows, bottom tab bar) so the
// transition reads as "content is reloading" rather than "the app froze".
private struct LanguageSwitchSkeletonView: View {
    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar placeholder
                HStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(BrandColor.surface)
                        .frame(width: 120, height: 18)
                    Spacer()
                    Circle()
                        .fill(BrandColor.surface)
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 24)

                // Cards
                VStack(spacing: 14) {
                    ForEach(0..<5, id: \.self) { i in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(BrandColor.surface)
                                .frame(width: 36, height: 36)
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(BrandColor.surface)
                                    .frame(width: i.isMultiple(of: 2) ? 160 : 200, height: 12)
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(BrandColor.surface.opacity(0.7))
                                    .frame(width: i.isMultiple(of: 2) ? 90 : 70, height: 10)
                            }
                            Spacer()
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(BrandColor.surface)
                                .frame(width: 50, height: 12)
                        }
                        .padding(14)
                        .background(BrandColor.surface.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Bottom tab bar placeholder
                HStack(spacing: 40) {
                    ForEach(0..<5, id: \.self) { _ in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(BrandColor.surface)
                                .frame(width: 22, height: 22)
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(BrandColor.surface.opacity(0.7))
                                .frame(width: 32, height: 8)
                        }
                    }
                }
                .padding(.bottom, 36)
            }
        }
        .shimmer()
    }
}

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("appLanguageDidChange")
}

// MARK: - Seed on first launch
// Called from ContentView.onAppear via a SwiftData-aware context
extension BudgetellaApp {
    static func seedCategoriesIfNeeded(in context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: "categoriesSeeded") else { return }
        let count = (try? context.fetchCount(FetchDescriptor<Category>())) ?? 0
        guard count == 0 else {
            UserDefaults.standard.set(true, forKey: "categoriesSeeded")
            return
        }
        Category.seedDefaults(for: "local").forEach { context.insert($0) }
        try? context.save()
        UserDefaults.standard.set(true, forKey: "categoriesSeeded")
    }

    static func seedSettingsIfNeeded(in context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<AppSettings>())) ?? 0
        guard count == 0 else { return }
        context.insert(AppSettings(userId: "local"))
        try? context.save()
    }

    static func migrateAddMissingCategories(in context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: "migration_addMissingCategories_v1") else { return }
        let existing = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let existingSlugs = Set(existing.map { $0.slug })
        let missing = CategorySlug.allCases.filter { !existingSlugs.contains($0.rawValue) }
        missing.enumerated().forEach { index, slug in
            context.insert(Category(
                userId: "local",
                name: slug.turkishName,
                slug: slug.rawValue,
                type: slug.type,
                iconName: slug.defaultIcon,
                colorHex: slug.defaultColorHex,
                isDefault: true,
                sortOrder: existing.count + index
            ))
        }
        if !missing.isEmpty { try? context.save() }
        UserDefaults.standard.set(true, forKey: "migration_addMissingCategories_v1")
    }

    static func migrateEnglishCategoryNames(in context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: "migration_englishCategoryNames_v1") else { return }
        let all = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let renames: [String: String] = ["Sale": "Ürün Satışı", "Utilities": "Faturalar"]
        for cat in all {
            if let newName = renames[cat.name] { cat.name = newName }
        }
        try? context.save()
        UserDefaults.standard.set(true, forKey: "migration_englishCategoryNames_v1")
    }
}
