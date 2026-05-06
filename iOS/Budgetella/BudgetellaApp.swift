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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(appReloadToken)
                .environment(\.locale, appLocale)
                .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
                    let raw = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first
                              ?? Locale.current.language.languageCode?.identifier
                              ?? "en"
                    appLocale = Locale(identifier: String(raw.prefix(2)))
                    appReloadToken = UUID()
                }
        }
        .modelContainer(modelContainer)
        .backgroundTask(.appRefresh("seed")) { }
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
