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
    }
}
