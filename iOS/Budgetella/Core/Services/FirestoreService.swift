//
//  FirestoreService.swift
//  Budgetella
//
//  Firestore CRUD — lokal-first mimarinin cloud sync katmanı.
//  Webapp firebase/db.ts → Swift port (sadece auth'lu kullanıcı için).
//
//  Koleksiyon yapısı:
//    users/{uid}/transactions/{id}
//    users/{uid}/categories/{id}
//    users/{uid}/settings/userSettings
//
//  Sign-in'de: Firestore → lokal SwiftData (overwrite)
//  Sign-out'ta: lokal temizlik (AuthService.clearLocalData)
//  Mutation'larda: önce lokal SwiftData, arka planda Firestore
//

import Foundation
import SwiftData
@preconcurrency import FirebaseFirestore

public actor FirestoreService {

    private let db = Firestore.firestore()

    // MARK: - Paths

    private func userRef(_ uid: String) -> DocumentReference {
        db.collection("users").document(uid)
    }

    private func transactionsRef(_ uid: String) -> CollectionReference {
        userRef(uid).collection("transactions")
    }

    private func categoriesRef(_ uid: String) -> CollectionReference {
        userRef(uid).collection("categories")
    }

    // MARK: - Upload (lokal → Firestore)

    public func uploadTransaction(_ tx: Transaction) async throws {
        let data: [String: Any] = [
            "id":               tx.id.uuidString,
            "userId":           tx.userId,
            "type":             tx.type.rawValue,
            "amount":           NSDecimalNumber(decimal: tx.amount).doubleValue,
            "currency":         tx.currency,
            "note":             tx.note,
            "categorySlug":     tx.category?.slug ?? "",
            "date":             Timestamp(date: tx.date),
            "status":           tx.status.rawValue,
            "isRecurring":      tx.isRecurring,
            "recurringInterval": tx.recurringInterval?.rawValue ?? "",
            "createdAt":        Timestamp(date: tx.createdAt),
            "updatedAt":        Timestamp(date: tx.updatedAt),
        ]
        try await transactionsRef(tx.userId)
            .document(tx.id.uuidString)
            .setData(data, merge: true)
    }

    public func deleteTransaction(id: UUID, userId: String) async throws {
        try await transactionsRef(userId).document(id.uuidString).delete()
    }

    public func uploadCategory(_ cat: Category) async throws {
        let data: [String: Any] = [
            "id":        cat.id.uuidString,
            "userId":    cat.userId,
            "name":      cat.name,
            "slug":      cat.slug ?? "",
            "type":      cat.type.rawValue,
            "iconName":  cat.iconName,
            "colorHex":  cat.colorHex,
            "isDefault": cat.isDefault,
            "sortOrder": cat.sortOrder,
        ]
        try await categoriesRef(cat.userId)
            .document(cat.id.uuidString)
            .setData(data, merge: true)
    }

    // MARK: - Fetch (Firestore → lokal)

    /// Sign-in sonrası kullanıcının Firestore verisini çekip SwiftData'ya yazar.
    public func fetchAndSync(userId: String, modelContext: ModelContext) async throws {
        async let txSnapshot  = transactionsRef(userId).getDocuments()
        async let catSnapshot = categoriesRef(userId).getDocuments()

        let (txDocs, catDocs) = try await (txSnapshot, catSnapshot)

        // Mevcut lokal transaction ve kategorileri temizle
        try modelContext.delete(model: Transaction.self)
        try modelContext.delete(model: Category.self)

        // Kategorileri önce ekle (transaction FK referansı için)
        for doc in catDocs.documents {
            if let cat = category(from: doc.data(), userId: userId) {
                modelContext.insert(cat)
            }
        }

        for doc in txDocs.documents {
            if let tx = transaction(from: doc.data(), userId: userId) {
                modelContext.insert(tx)
            }
        }
    }

    // MARK: - Delete User Data (hesap sil)

    public func deleteUserData(userId: String) async throws {
        let batch = db.batch()
        let txDocs  = try await transactionsRef(userId).getDocuments()
        let catDocs = try await categoriesRef(userId).getDocuments()
        txDocs.documents.forEach  { batch.deleteDocument($0.reference) }
        catDocs.documents.forEach { batch.deleteDocument($0.reference) }
        batch.deleteDocument(userRef(userId))
        try await batch.commit()
    }

    // MARK: - Mappers

    private func transaction(from data: [String: Any], userId: String) -> Transaction? {
        guard
            let idStr  = data["id"]     as? String, let id = UUID(uuidString: idStr),
            let typeRaw = data["type"]  as? String, let type = TransactionType(rawValue: typeRaw),
            let amount  = data["amount"] as? Double,
            let note    = data["note"]   as? String,
            let dateTS  = data["date"]   as? Timestamp
        else { return nil }

        let statusRaw = data["status"] as? String ?? "completed"
        let status    = TransactionStatus(rawValue: statusRaw) ?? .completed
        let currency  = data["currency"] as? String ?? "TRY"

        return Transaction(
            id: id,
            userId: userId,
            type: type,
            amount: Decimal(amount),
            currency: currency,
            note: note,
            date: dateTS.dateValue(),
            status: status
        )
    }

    private func category(from data: [String: Any], userId: String) -> Category? {
        guard
            let idStr   = data["id"]       as? String, let id = UUID(uuidString: idStr),
            let name    = data["name"]     as? String,
            let typeRaw = data["type"]     as? String, let type = TransactionType(rawValue: typeRaw),
            let icon    = data["iconName"] as? String,
            let color   = data["colorHex"] as? String
        else { return nil }

        return Category(
            id: id,
            userId: userId,
            name: name,
            slug: data["slug"] as? String,
            type: type,
            iconName: icon,
            colorHex: color,
            isDefault: data["isDefault"] as? Bool ?? false,
            sortOrder: data["sortOrder"] as? Int ?? 0
        )
    }
}
