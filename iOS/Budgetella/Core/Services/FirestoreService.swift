//
//  FirestoreService.swift
//  Budgetella
//
//  Firestore CRUD — local-first mimarinin cloud sync katmanı.
//
//  Koleksiyon yapısı:
//    users/{uid}/transactions/{id}
//    users/{uid}/categories/{id}
//
//  Sync stratejisi:
//  - Mutation'da: SwiftData'ya yaz → arka planda Firestore'a push (fire & forget)
//  - Login'de: fetchAndSync() → Firestore'dan indir → SwiftData'yı overwrite
//  - Yeni kullanıcı: fetchAndSync() boş döner → lokal default kategorileri Firestore'a yükle
//

import Foundation
import SwiftData
@preconcurrency import FirebaseFirestore

@MainActor
@Observable
public final class FirestoreService {

    public static let shared = FirestoreService()
    private init() {}

    public var isSyncing = false

    private let db = Firestore.firestore()

    // MARK: - Collection Paths

    private func userRef(_ uid: String) -> DocumentReference {
        db.collection("users").document(uid)
    }

    private func transactionsRef(_ uid: String) -> CollectionReference {
        userRef(uid).collection("transactions")
    }

    private func categoriesRef(_ uid: String) -> CollectionReference {
        userRef(uid).collection("categories")
    }

    // MARK: - Upload: Lokal → Firestore

    public func uploadTransaction(_ tx: Transaction) async throws {
        let data: [String: Any] = [
            "id":                tx.id.uuidString,
            "userId":            tx.userId,
            "type":              tx.type.rawValue,
            "amount":            NSDecimalNumber(decimal: tx.amount).doubleValue,
            "currency":          tx.currency,
            "note":              tx.note,
            "categorySlug":      tx.category?.slug ?? "",
            "date":              Timestamp(date: tx.date),
            "status":            tx.status.rawValue,
            "isRecurring":       tx.isRecurring,
            "recurringInterval": tx.recurringInterval?.rawValue ?? "",
            "createdAt":         Timestamp(date: tx.createdAt),
            "updatedAt":         Timestamp(date: tx.updatedAt),
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

    // MARK: - Batch Upload (import sonrası)

    /// Fire-and-forget: tüm transaksiyonları paralel task'larla Firestore'a gönderir.
    public func batchUploadTransactions(_ txs: [Transaction]) {
        for tx in txs {
            Task {
                do {
                    try await self.uploadTransaction(tx)
                } catch {
                    print("[FirestoreService] batchUpload failed for \(tx.id): \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Fetch & Sync: Firestore → SwiftData (login sonrası)

    /// Login sonrası çağrılır. Firestore'dan indirir, SwiftData'yı günceller.
    /// - Yeni kullanıcı (boş Firestore): lokal default kategorileri Firestore'a yükler.
    /// - Mevcut kullanıcı: kategorileri + transaksiyonları indirir, kategori ilişkilerini kurar.
    public func fetchAndSync(userId: String, modelContext: ModelContext) async throws {
        isSyncing = true
        defer { isSyncing = false }

        // Purge any local data that belongs to a different user before proceeding.
        // This guards against cross-user leaks when the auth session changes without
        // a proper sign-out (e.g. token expiry, account switching).
        let wrongTxs = ((try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? [])
            .filter { $0.userId != userId }
        let wrongCats = ((try? modelContext.fetch(FetchDescriptor<Category>())) ?? [])
            .filter { $0.userId != userId }
        if !wrongTxs.isEmpty || !wrongCats.isEmpty {
            wrongTxs.forEach { modelContext.delete($0) }
            wrongCats.forEach { modelContext.delete($0) }
            try? modelContext.save()
        }

        async let txFetch  = transactionsRef(userId).getDocuments()
        async let catFetch = categoriesRef(userId).getDocuments()
        let (txDocs, catDocs) = try await (txFetch, catFetch)

        if catDocs.documents.isEmpty {
            // Yeni / boş Firestore — lokal veriyi SİLME, koru
            let localCats = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
            if localCats.isEmpty {
                // Hiç kategori yok → default'ları seed et ve Firestore'a yükle
                let cats = Category.seedDefaults(for: userId)
                cats.forEach { modelContext.insert($0) }
                try? modelContext.save()
                Task { for cat in cats { try? await self.uploadCategory(cat) } }
            } else {
                // Lokal import verisi var → userId'yi gerçek UID'ye migrate et ve Firestore'a yükle
                let localTxs = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
                for tx in localTxs where tx.userId != userId { tx.userId = userId }
                for cat in localCats where cat.userId != userId { cat.userId = userId }
                try? modelContext.save()
                Task { for cat in localCats { try? await self.uploadCategory(cat) } }
                batchUploadTransactions(localTxs)
            }
            UserDefaults.standard.set(true, forKey: "categoriesSeeded")
            return
        }

        // Firestore'da veri var → lokal veriyi temizle ve Firestore'dan indir
        let localTxsToDelete = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
        localTxsToDelete.forEach { modelContext.delete($0) }
        try? modelContext.save()
        let localCatsToDelete = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        localCatsToDelete.forEach { modelContext.delete($0) }

        // Kategorileri ekle + slug → Category map oluştur
        var categoryBySlug: [String: Category] = [:]
        for doc in catDocs.documents {
            if let cat = category(from: doc.data(), userId: userId) {
                modelContext.insert(cat)
                if let slug = cat.slug, !slug.isEmpty {
                    categoryBySlug[slug] = cat
                }
            }
        }

        // Transaksiyonları ekle, kategori ilişkisini slug üzerinden kur
        for doc in txDocs.documents {
            if let tx = transaction(from: doc.data(), userId: userId) {
                let catSlug = doc.data()["categorySlug"] as? String ?? ""
                tx.category = categoryBySlug[catSlug]
                modelContext.insert(tx)
            }
        }

        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: "categoriesSeeded")
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

    // MARK: - Private Mappers

    private func transaction(from data: [String: Any], userId: String) -> Transaction? {
        guard
            let idStr   = data["id"]     as? String, let id = UUID(uuidString: idStr),
            let typeRaw = data["type"]   as? String, let type = TransactionType(rawValue: typeRaw),
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
