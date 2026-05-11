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

    // Active snapshot listeners — torn down on sign-out or when observing a
    // different uid. Both collections (transactions + categories) get one
    // listener each so edits made on Android land in SwiftData within a
    // few hundred ms without forcing the user to relaunch.
    private var observingUid: String?
    private var transactionsListener: ListenerRegistration?
    private var categoriesListener: ListenerRegistration?

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
        // Cross-platform doc-ID convention: lowercase. Java's UUID.toString()
        // is lowercase, Swift's UUID.uuidString is uppercase — so without
        // normalizing one side, every iOS write would create a NEW uppercase
        // doc while Android-written lowercase docs lingered as orphans, and
        // iOS deletes targeted at the uppercase path missed Android-written
        // docs entirely. Standardising on lowercase here keeps deletes
        // round-trip-clean across platforms.
        let docId = tx.id.uuidString.lowercased()
        let data: [String: Any] = [
            "id":                docId,
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
            .document(docId)
            .setData(data, merge: true)
        // Migration: clean up the legacy uppercase variant of the doc if it
        // exists — historical iOS writes landed at the uppercase path. The
        // delete is best-effort and idempotent (no-op if the doc never
        // existed).
        let upperId = tx.id.uuidString
        if upperId != docId {
            try? await transactionsRef(tx.userId).document(upperId).delete()
        }
    }

    public func deleteTransaction(id: UUID, userId: String) async throws {
        // Delete both case-variants of the doc path. Going forward all writes
        // are lowercase; legacy uppercase docs (pre-v1.0.1 build 3) get
        // cleaned up on first delete touch.
        let lower = id.uuidString.lowercased()
        let upper = id.uuidString
        try? await transactionsRef(userId).document(lower).delete()
        if upper != lower {
            try? await transactionsRef(userId).document(upper).delete()
        }
    }

    public func uploadCategory(_ cat: Category) async throws {
        let docId = cat.id.uuidString.lowercased()
        let data: [String: Any] = [
            "id":        docId,
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
            .document(docId)
            .setData(data, merge: true)
        let upperId = cat.id.uuidString
        if upperId != docId {
            try? await categoriesRef(cat.userId).document(upperId).delete()
        }
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

    // MARK: - Live snapshot listeners (real-time sync from another device)

    /// Subscribe to transactions + categories for `userId` so edits made on
    /// Android (or any other client) land in SwiftData immediately. Call from
    /// MainTabView.task after fetchAndSync. Idempotent.
    public func startObserving(userId: String, modelContext: ModelContext) {
        guard observingUid != userId else { return }
        stopObserving()
        observingUid = userId

        categoriesListener = categoriesRef(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                print("[FirestoreService] categories listener error: \(error.localizedDescription)")
                return
            }
            guard let snapshot else { return }
            // Capture document changes off the main thread, then dispatch the
            // tiny delta (typically 1–3 docs) to the main actor. Reading
            // `snapshot.documentChanges` is the cheap way to avoid iterating
            // all N rows on every listener firing — for the Ozan account
            // that's ~2k transactions per snapshot and was triggering a
            // detached-backing-data crash mid-render.
            let changes = snapshot.documentChanges
            Task { @MainActor in
                self.applyCategoryChanges(changes, userId: userId, modelContext: modelContext)
            }
        }

        transactionsListener = transactionsRef(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                print("[FirestoreService] transactions listener error: \(error.localizedDescription)")
                return
            }
            guard let snapshot else { return }
            let changes = snapshot.documentChanges
            Task { @MainActor in
                self.applyTransactionChanges(changes, userId: userId, modelContext: modelContext)
            }
        }
    }

    public func stopObserving() {
        transactionsListener?.remove()
        categoriesListener?.remove()
        transactionsListener = nil
        categoriesListener = nil
        observingUid = nil
    }

    /// Process only the docs that Firestore reports as added / modified /
    /// removed since the previous snapshot. Cheap (typically 1–3 docs per
    /// firing) and safe — we never iterate live model objects that the UI is
    /// still rendering, which is what caused the detached-backing-data crash.
    @MainActor
    private func applyCategoryChanges(
        _ changes: [DocumentChange],
        userId: String,
        modelContext: ModelContext,
    ) {
        if changes.isEmpty { return }
        for change in changes {
            let data = change.document.data()
            guard let idStr = data["id"] as? String, let uuid = UUID(uuidString: idStr) else { continue }
            switch change.type {
            case .added, .modified:
                if let local = fetchCategory(by: uuid, in: modelContext) {
                    if let name = data["name"] as? String { local.name = name }
                    if let slug = data["slug"] as? String { local.slug = slug.isEmpty ? nil : slug }
                    if let typeRaw = data["type"] as? String, let t = TransactionType(rawValue: typeRaw) { local.type = t }
                    if let icon = data["iconName"] as? String { local.iconName = icon }
                    if let color = data["colorHex"] as? String { local.colorHex = color }
                    if let isDefault = data["isDefault"] as? Bool { local.isDefault = isDefault }
                    if let sortOrder = data["sortOrder"] as? Int { local.sortOrder = sortOrder }
                } else if let cat = category(from: data, userId: userId) {
                    modelContext.insert(cat)
                }
            case .removed:
                if let local = fetchCategory(by: uuid, in: modelContext), local.userId == userId {
                    modelContext.delete(local)
                }
            @unknown default:
                break
            }
        }
        try? modelContext.save()
    }

    @MainActor
    private func applyTransactionChanges(
        _ changes: [DocumentChange],
        userId: String,
        modelContext: ModelContext,
    ) {
        if changes.isEmpty { return }
        // Build slug → Category lookup once for the batch. First-write-wins on
        // duplicate slugs to avoid Dictionary(uniqueKeysWithValues:) traps.
        let allCats = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        var catBySlug: [String: Category] = [:]
        for c in allCats {
            if let s = c.slug, !s.isEmpty, catBySlug[s] == nil {
                catBySlug[s] = c
            }
        }

        for change in changes {
            let data = change.document.data()
            guard let idStr = data["id"] as? String, let uuid = UUID(uuidString: idStr) else { continue }
            switch change.type {
            case .added, .modified:
                let catSlug = data["categorySlug"] as? String ?? ""
                let resolvedCat = catBySlug[catSlug]
                if let local = fetchTransaction(by: uuid, in: modelContext) {
                    if let amount = data["amount"] as? Double { local.amount = Decimal(amount) }
                    if let typeRaw = data["type"] as? String, let t = TransactionType(rawValue: typeRaw) { local.type = t }
                    if let note = data["note"] as? String { local.note = note }
                    if let dateTS = data["date"] as? Timestamp { local.date = dateTS.dateValue() }
                    if let statusRaw = data["status"] as? String, let s = TransactionStatus(rawValue: statusRaw) { local.status = s }
                    if let currency = data["currency"] as? String { local.currency = currency }
                    local.category = resolvedCat
                } else if let tx = transaction(from: data, userId: userId) {
                    tx.category = resolvedCat
                    modelContext.insert(tx)
                }
            case .removed:
                if let local = fetchTransaction(by: uuid, in: modelContext), local.userId == userId {
                    modelContext.delete(local)
                }
            @unknown default:
                break
            }
        }
        try? modelContext.save()
    }

    @MainActor
    private func fetchCategory(by id: UUID, in modelContext: ModelContext) -> Category? {
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.id == id })
        return (try? modelContext.fetch(descriptor))?.first
    }

    @MainActor
    private func fetchTransaction(by id: UUID, in modelContext: ModelContext) -> Transaction? {
        let descriptor = FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == id })
        return (try? modelContext.fetch(descriptor))?.first
    }

    // MARK: - Delete User Data (hesap sil)

    public func deleteUserData(userId: String) async throws {
        let txDocs  = try await transactionsRef(userId).getDocuments()
        let catDocs = try await categoriesRef(userId).getDocuments()
        let allRefs: [DocumentReference] = txDocs.documents.map { $0.reference }
            + catDocs.documents.map { $0.reference }
            + [userRef(userId)]
        // Firestore batch limit is 500 — chunk to stay safe
        let chunks = stride(from: 0, to: allRefs.count, by: 490).map {
            Array(allRefs[$0..<min($0 + 490, allRefs.count)])
        }
        for chunk in chunks {
            let batch = db.batch()
            chunk.forEach { batch.deleteDocument($0) }
            try await batch.commit()
        }
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
