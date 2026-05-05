//
//  BudgetellaShortcuts.swift
//  Budgetella
//
//  AppShortcutsProvider — Siri trigger phrases (English).
//
//  Flow: "Hey Siri, add expense in Budgetella"
//        → Siri: "How much?"
//        → user says amount
//        → saved as expense, Siri confirms
//
//  Note: AppShortcutsBuilder does not support closures or variable declarations;
//  only plain AppShortcut initialisations are allowed as top-level statements.
//

import AppIntents

struct BudgetellaShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTransactionIntent(),
            phrases: [
                "Add expense in \(.applicationName)",
                "Add expense to \(.applicationName)",
                "Add transaction in \(.applicationName)",
                "Add transaction to \(.applicationName)",
                "Log expense in \(.applicationName)",
                "Log a transaction in \(.applicationName)",
            ],
            shortTitle: "Add Transaction",
            systemImageName: "plus.circle.fill"
        )
    }
}
