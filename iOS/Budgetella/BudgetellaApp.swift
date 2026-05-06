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
        do {
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
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("SwiftData ModelContainer init failed: \(error)")
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
