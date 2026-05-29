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

    // Background SwiftData merge engine — created lazily from the container.
    // ALL Firestore→SwiftData writes run on its private background context so
    // the main thread never blocks (keyboard/scroll stay snappy during sync).
    private var _syncEngine: SyncEngine?
    private func engine(for ctx: ModelContext) -> SyncEngine {
        if let existing = _syncEngine { return existing }
        let made = SyncEngine(modelContainer: ctx.container)
        _syncEngine = made
        return made
    }

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
        let syncStart = CFAbsoluteTimeGetCurrent()
        EntryPerf.event("fetchAndSync START")

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

        // Firestore'da veri var → merge'i ARKA PLAN aktöründe yap. Main thread
        // hiç bloke olmaz (ilk açılışta bile klavye/scroll akıcı). Önce ucuz
        // parse → Sendable DTO, sonra background ModelContext'te upsert+reconcile.
        let catDTOs = catDocs.documents.compactMap { catDTO(from: $0.data(), userId: userId) }
        let txDTOs  = txDocs.documents.compactMap { txDTO(from: $0.data(), userId: userId) }
        await engine(for: modelContext).reconcile(userId: userId, cats: catDTOs, txs: txDTOs)
        EntryPerf.event("fetchAndSync END — cats=\(catDocs.documents.count) txs=\(txDocs.documents.count) in \(Int((CFAbsoluteTimeGetCurrent() - syncStart) * 1000)) ms")
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
        let eng = engine(for: modelContext)

        categoriesListener = categoriesRef(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                print("[FirestoreService] categories listener error: \(error.localizedDescription)")
                return
            }
            guard let snapshot else { return }
            // Parse the delta into Sendable DTOs here (off the main thread), then
            // merge on the background engine — the main actor is never touched.
            let deltas: [SyncChange<CatDTO>] = snapshot.documentChanges.compactMap { (ch) -> SyncChange<CatDTO>? in
                let data = ch.document.data()
                guard let idStr = data["id"] as? String, let id = UUID(uuidString: idStr) else { return nil }
                switch ch.type {
                case .removed: return .remove(id)
                case .added, .modified: return self.catDTO(from: data, userId: userId).map { .upsert($0) }
                @unknown default: return nil
                }
            }
            Task { await eng.applyCategoryChanges(deltas) }
        }

        transactionsListener = transactionsRef(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                print("[FirestoreService] transactions listener error: \(error.localizedDescription)")
                return
            }
            guard let snapshot else { return }
            let applyStart = CFAbsoluteTimeGetCurrent()
            let deltas: [SyncChange<TxDTO>] = snapshot.documentChanges.compactMap { (ch) -> SyncChange<TxDTO>? in
                let data = ch.document.data()
                guard let idStr = data["id"] as? String, let id = UUID(uuidString: idStr) else { return nil }
                switch ch.type {
                case .removed: return .remove(id)
                case .added, .modified: return self.txDTO(from: data, userId: userId).map { .upsert($0) }
                @unknown default: return nil
                }
            }
            let count = deltas.count
            Task {
                await eng.applyTransactionChanges(deltas)
                EntryPerf.event("listener TX apply — \(count) changes in \(Int((CFAbsoluteTimeGetCurrent() - applyStart) * 1000)) ms (bg)")
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
                    applyCategoryFields(data, to: local)
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
        let applyStart = CFAbsoluteTimeGetCurrent()
        // Build slug → Category lookup once for the batch. First-write-wins on
        // duplicate slugs to avoid Dictionary(uniqueKeysWithValues:) traps.
        let allCats = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        var catBySlug: [String: Category] = [:]
        for c in allCats {
            if let s = c.slug, !s.isEmpty, catBySlug[s] == nil {
                catBySlug[s] = c
            }
        }

        // Large batch (first snapshot = every doc as .added) → one bulk fetch
        // into an id-map beats thousands of per-doc predicate fetches. Small
        // live edits keep the cheap per-doc path (no map-build overhead).
        let useMap = changes.count > 30
        var txById: [UUID: Transaction] = [:]
        if useMap {
            let allTx = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
            for t in allTx { txById[t.id] = t }
        }
        func localTx(_ id: UUID) -> Transaction? {
            useMap ? txById[id] : fetchTransaction(by: id, in: modelContext)
        }

        for change in changes {
            let data = change.document.data()
            guard let idStr = data["id"] as? String, let uuid = UUID(uuidString: idStr) else { continue }
            switch change.type {
            case .added, .modified:
                let catSlug = data["categorySlug"] as? String ?? ""
                let resolvedCat = catBySlug[catSlug]
                if let local = localTx(uuid) {
                    // Skip rows fetchAndSync already wrote this launch (unchanged)
                    // → first snapshot becomes ~zero writes.
                    let remoteUpdated = (data["updatedAt"] as? Timestamp)?.dateValue()
                    let unchanged = remoteUpdated.map { abs(local.updatedAt.timeIntervalSince($0)) < 0.001 } ?? false
                    if !unchanged {
                        applyTransactionFields(data, to: local)
                        local.category = resolvedCat
                    } else if local.category !== resolvedCat {
                        local.category = resolvedCat
                    }
                } else if let tx = transaction(from: data, userId: userId) {
                    if let ts = data["updatedAt"] as? Timestamp { tx.updatedAt = ts.dateValue() }
                    if let ts = data["createdAt"] as? Timestamp { tx.createdAt = ts.dateValue() }
                    tx.category = resolvedCat
                    modelContext.insert(tx)
                    if useMap { txById[uuid] = tx }
                }
            case .removed:
                if let local = localTx(uuid), local.userId == userId {
                    modelContext.delete(local)
                }
            @unknown default:
                break
            }
        }
        try? modelContext.save()
        EntryPerf.event("listener TX apply — \(changes.count) changes in \(Int((CFAbsoluteTimeGetCurrent() - applyStart) * 1000)) ms")
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

    // Shared field-appliers — single source of truth for the upsert path used
    // by both fetchAndSync (initial reconcile) and the live snapshot listeners.
    private func applyCategoryFields(_ data: [String: Any], to local: Category) {
        if let name = data["name"] as? String { local.name = name }
        if let slug = data["slug"] as? String { local.slug = slug.isEmpty ? nil : slug }
        if let typeRaw = data["type"] as? String, let t = TransactionType(rawValue: typeRaw) { local.type = t }
        if let icon = data["iconName"] as? String { local.iconName = icon }
        if let color = data["colorHex"] as? String { local.colorHex = color }
        if let isDefault = data["isDefault"] as? Bool { local.isDefault = isDefault }
        if let sortOrder = data["sortOrder"] as? Int { local.sortOrder = sortOrder }
    }

    private func applyTransactionFields(_ data: [String: Any], to local: Transaction) {
        if let amount = data["amount"] as? Double { local.amount = Decimal(amount) }
        if let typeRaw = data["type"] as? String, let t = TransactionType(rawValue: typeRaw) { local.type = t }
        if let note = data["note"] as? String { local.note = note }
        if let dateTS = data["date"] as? Timestamp { local.date = dateTS.dateValue() }
        if let statusRaw = data["status"] as? String, let s = TransactionStatus(rawValue: statusRaw) { local.status = s }
        if let currency = data["currency"] as? String { local.currency = currency }
        // Keep local.updatedAt aligned with the server so the next launch's
        // upsert can skip this row when nothing changed.
        if let ts = data["updatedAt"] as? Timestamp { local.updatedAt = ts.dateValue() }
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

    // MARK: - DTO parsers ([String:Any] → Sendable, safe to hand to SyncEngine)
    // nonisolated so the Firestore listener thread can parse before delegating.

    nonisolated func catDTO(from data: [String: Any], userId: String) -> CatDTO? {
        guard
            let idStr = data["id"] as? String, let id = UUID(uuidString: idStr),
            let name  = data["name"] as? String,
            let type  = data["type"] as? String,
            let icon  = data["iconName"] as? String,
            let color = data["colorHex"] as? String
        else { return nil }
        let slug = (data["slug"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        return CatDTO(
            id: id, userId: userId, name: name, slug: slug, type: type,
            iconName: icon, colorHex: color,
            isDefault: data["isDefault"] as? Bool ?? false,
            sortOrder: data["sortOrder"] as? Int ?? 0
        )
    }

    nonisolated func txDTO(from data: [String: Any], userId: String) -> TxDTO? {
        guard
            let idStr  = data["id"] as? String, let id = UUID(uuidString: idStr),
            let type   = data["type"] as? String,
            let amount = data["amount"] as? Double,
            let note   = data["note"] as? String,
            let dateTS = data["date"] as? Timestamp
        else { return nil }
        return TxDTO(
            id: id, userId: userId, type: type, amount: amount,
            currency: data["currency"] as? String ?? "TRY",
            note: note, categorySlug: data["categorySlug"] as? String ?? "",
            date: dateTS.dateValue(),
            status: data["status"] as? String ?? "completed",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
        )
    }
}
