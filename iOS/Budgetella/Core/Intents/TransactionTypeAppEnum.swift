//
//  TransactionTypeAppEnum.swift
//  Budgetella
//
//  AppEnum wrapper for TransactionType — Siri parametre seçici.
//

import AppIntents

enum TransactionTypeAppEnum: String, AppEnum {
    case expense
    case income

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "İşlem Türü")

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .expense: DisplayRepresentation(title: "Expense", image: .init(systemName: "arrow.down.right")),
        .income:  DisplayRepresentation(title: "Income",  image: .init(systemName: "arrow.up.right")),
    ]
}
