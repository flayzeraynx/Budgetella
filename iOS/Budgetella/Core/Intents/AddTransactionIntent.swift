//
//  AddTransactionIntent.swift
//  Budgetella
//
//  App Intent — "Hey Siri, Budgetella'ya 4500 lira benzin ekle"
//  iOS 17+ App Intents framework, SiriKit entitlement gerektirmez.
//

import AppIntents
import SwiftData
import Foundation

struct AddTransactionIntent: AppIntent {

    static let title: LocalizedStringResource = "İşlem Ekle"
    static let description = IntentDescription(
        "Budgetella'ya sesli komutla hızlıca gelir ya da gider ekle.",
        categoryName: "İşlem"
    )
    // App'i açmadan arka planda çalışır, Siri sadece onay diyaloğunu gösterir
    static let openAppWhenRun = false

    // MARK: - Parameters

    @Parameter(
        title: "Amount",
        description: "Transaction amount (e.g. 450)",
        controlStyle: .field,
        inclusiveRange: (0.01, 9_999_999),
        requestValueDialog: IntentDialog("How much?")
    )
    var amount: Double

    @Parameter(
        title: "Type",
        description: "Expense or Income",
        default: .expense,
        requestValueDialog: IntentDialog("Expense or income?")
    )
    var transactionType: TransactionTypeAppEnum

    @Parameter(
        title: "Note",
        description: "What for? (e.g. gas, groceries, rent)",
        default: ""
    )
    var note: String

    // MARK: - Parameter Summary

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$amount)") {
            \.$transactionType
            \.$note
        }
    }

    // MARK: - Perform

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // ── SwiftData context ─────────────────────────────────────────────
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
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        // ── Auto-categorize via keyword matching ──────────────────────────
        let categories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let prediction = KeywordCategorizer.predict(from: note)
        let category: Category? = {
            guard let slug = prediction?.slug.rawValue else { return nil }
            return categories.first { $0.slug == slug }
        }()

        // ── Build & persist transaction ───────────────────────────────────
        let userId = UserDefaults.standard.string(forKey: "currentUserId") ?? "local"
        let txType: TransactionType = transactionType == .expense ? .expense : .income
        let tx = Transaction(
            userId: userId,
            type: txType,
            amount: Decimal(amount),
            note: note,
            category: category
        )
        context.insert(tx)
        try context.save()

        // ── Firestore upload — synchronous, BEFORE container goes out of scope ──
        // Task { } causes a fatal crash: context.reset destroys tx before the
        // detached task runs. Awaiting directly keeps the container alive.
        try? await FirestoreService.shared.uploadTransaction(tx)

        // ── Siri confirmation dialog ──────────────────────────────────────
        let symbol    = txType == .expense ? "↓" : "↑"
        let typeWord  = txType == .expense ? "expense" : "income"
        let formatted = String(format: "%.0f", amount)
        let catName   = category?.name ?? ""
        let noteLabel = note.isEmpty ? typeWord : note
        let dialog: String = catName.isEmpty
            ? "\(symbol) ₺\(formatted) \(noteLabel) added."
            : "\(symbol) ₺\(formatted) \(noteLabel) · \(catName) added."

        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}
