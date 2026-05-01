//
//  QuickEntryViewModel.swift
//  Budgetella
//
//  Hızlı giriş state + numpad mantığı + AI kategori önerisi
//

import Foundation
import SwiftData

@MainActor @Observable final class QuickEntryViewModel {

    // MARK: - Form state
    var rawInput: String = ""          // "240" | "240," | "240,50"
    var transactionType: TransactionType = .expense
    var note: String = ""
    var selectedCategoryId: UUID?
    var showCategoryPicker = false
    var errorMessage: String?

    // MARK: - AI suggestions (on-device)
    var aiSuggestions: [CategoryPrediction] = []

    // MARK: - Computed

    var canSave: Bool { amountDecimal > 0 }

    var amountDecimal: Decimal {
        let normalized = rawInput.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized) ?? 0
    }

    /// Tam sayı kısmı ("240")
    var wholePart: String {
        guard !rawInput.isEmpty else { return "0" }
        return rawInput.split(separator: ",", omittingEmptySubsequences: false)
            .first.map(String.init) ?? "0"
    }

    /// Kuruş kısmı: nil = ondalık girilmedi, "" = sadece virgül, "5" veya "50"
    var fracPart: String? {
        guard rawInput.contains(",") else { return nil }
        let parts = rawInput.split(separator: ",", omittingEmptySubsequences: false)
        return parts.count > 1 ? String(parts[1]) : ""
    }

    // MARK: - Numpad input

    func appendDigit(_ d: String) {
        if rawInput.contains(",") {
            let parts = rawInput.split(separator: ",", omittingEmptySubsequences: false)
            let fracLen = parts.count > 1 ? parts[1].count : 0
            if fracLen < 2 { rawInput += d }
        } else {
            if rawInput == "0" {
                rawInput = d
            } else if rawInput.count < 10 {
                rawInput += d
            }
        }
    }

    func appendDecimal() {
        if rawInput.isEmpty { rawInput = "0" }
        if !rawInput.contains(",") { rawInput += "," }
    }

    func backspace() {
        guard !rawInput.isEmpty else { return }
        rawInput.removeLast()
    }

    // MARK: - AI suggestions

    func updateSuggestions() {
        aiSuggestions = KeywordCategorizer.topPredictions(from: note, count: 3)
    }

    // MARK: - Save

    func save(modelContext: ModelContext, categories: [Category], userId: String) {
        guard amountDecimal > 0 else {
            errorMessage = "Tutar 0'dan büyük olmalı."
            return
        }
        let category = selectedCategoryId.flatMap { id in categories.first { $0.id == id } }
        let tx = Transaction(
            userId: userId.isEmpty ? "local" : userId,
            type: transactionType,
            amount: amountDecimal,
            note: note,
            category: category
        )
        modelContext.insert(tx)
        reset()
    }

    private func reset() {
        rawInput = ""
        note = ""
        selectedCategoryId = nil
        aiSuggestions = []
        errorMessage = nil
    }
}
