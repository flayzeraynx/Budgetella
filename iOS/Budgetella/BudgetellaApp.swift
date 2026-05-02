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
@preconcurrency import FirebaseCore

@main
struct BudgetellaApp: App {

    let modelContainer: ModelContainer

    init() {
        // Firebase — GoogleService-Info.plist'ten otomatik konfigürasyon
        FirebaseApp.configure()

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

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        .backgroundTask(.appRefresh("seed")) { }
    }
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
}
