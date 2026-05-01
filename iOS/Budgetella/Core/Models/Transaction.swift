//
//  Transaction.swift
//  Budgetella
//
//  SwiftData @Model — kullanıcının her bir gelir/gider kaydı.
//  Webapp Dexie schema (`finVaultDB_v1` v4) ile alan-alan uyumlu;
//  JSON import sırasında "description" alanı → "note"a map ediliyor.
//

import Foundation
import SwiftData

public enum TransactionType: String, Codable, CaseIterable, Sendable {
    case income
    case expense
}

public enum TransactionStatus: String, Codable, CaseIterable, Sendable {
    case completed
    case pending
    case planned
}

public enum RecurringInterval: String, Codable, CaseIterable, Sendable {
    case daily
    case weekly
    case monthly
    case yearly
}

@Model
public final class Transaction {

    @Attribute(.unique) public var id: UUID
    public var userId: String

    public var type: TransactionType
    public var amount: Decimal
    public var currency: String
    public var note: String  // Webapp schema'sındaki "description" karşılığı

    @Relationship(deleteRule: .nullify) public var category: Category?

    public var date: Date
    public var status: TransactionStatus

    // Recurring fields
    public var isRecurring: Bool
    public var recurringInterval: RecurringInterval?
    public var recurringEndDate: Date?
    /// Recurring transaction'ın "şablonu" varsa burada referans tutulur.
    /// Ana şablon için nil.
    public var originalTransactionId: UUID?

    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        userId: String,
        type: TransactionType,
        amount: Decimal,
        currency: String = "TRY",
        note: String,
        category: Category? = nil,
        date: Date = .now,
        status: TransactionStatus = .completed,
        isRecurring: Bool = false,
        recurringInterval: RecurringInterval? = nil,
        recurringEndDate: Date? = nil,
        originalTransactionId: UUID? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.amount = amount
        self.currency = currency
        self.note = note
        self.category = category
        self.date = date
        self.status = status
        self.isRecurring = isRecurring
        self.recurringInterval = recurringInterval
        self.recurringEndDate = recurringEndDate
        self.originalTransactionId = originalTransactionId
        self.createdAt = .now
        self.updatedAt = .now
    }
}

public extension Transaction {
    /// Pozitif/negatif işaretli tutar — UI hesaplamalarında kullanışlı.
    var signedAmount: Decimal {
        type == .income ? amount : -amount
    }

    /// Recurring şablon mu, yoksa türetilmiş bir instance mı?
    var isRecurringTemplate: Bool {
        isRecurring && originalTransactionId == nil
    }
}
