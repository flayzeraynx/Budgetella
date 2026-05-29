//
//  SyncEngine.swift
//  Budgetella
//
//  Background SwiftData merge engine. Runs ALL Firestore→SwiftData writes on a
//  private ModelContext bound to a background executor (@ModelActor), so the
//  main thread is never blocked — the keyboard, FAB and scrolling stay snappy
//  even during a large first-launch sync.
//
//  FirestoreService parses Firestore documents into the Sendable DTOs below
//  (it owns the FirebaseFirestore import); this engine only ever touches
//  Sendable value types + its own @Model objects, satisfying Swift 6 isolation.
//
//  Source of truth is Firestore; local SwiftData is a rebuildable cache.
//  reconcile() deletes LOCAL rows the server no longer has — it never pushes
//  deletes back to Firestore, so a bug here can only drop the local cache
//  (recoverable by re-sync), never the cloud copy.
//

import Foundation
import SwiftData

// MARK: - Sendable DTOs (safe to cross actor boundaries)

struct CatDTO: Sendable {
    let id: UUID
    let userId: String
    let name: String
    let slug: String?
    let type: String
    let iconName: String
    let colorHex: String
    let isDefault: Bool
    let sortOrder: Int
}

struct TxDTO: Sendable {
    let id: UUID
    let userId: String
    let type: String
    let amount: Double
    let currency: String
    let note: String
    let categorySlug: String
    let date: Date
    let status: String
    let createdAt: Date?
    let updatedAt: Date?
}

enum SyncChange<T: Sendable>: Sendable {
    case upsert(T)
    case remove(UUID)
}

// MARK: - Background merge actor

@ModelActor
actor SyncEngine {

    /// Initial full pull: upsert everything, skip rows whose `updatedAt` is
    /// unchanged (no write), and delete local rows missing from the server.
    func reconcile(userId: String, cats: [CatDTO], txs: [TxDTO]) {
        // One bulk fetch each → O(1) dictionary lookups (no per-doc queries).
        let localCats = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        let localTxs = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []

        // Privacy guard — purge any rows belonging to a different account
        // (e.g. token expiry / account switch without a clean sign-out).
        for c in localCats where c.userId != userId { modelContext.delete(c) }
        for t in localTxs where t.userId != userId { modelContext.delete(t) }

        var catById: [UUID: Category] = [:]
        for c in localCats where c.userId == userId { catById[c.id] = c }
        var txById: [UUID: Transaction] = [:]
        for t in localTxs where t.userId == userId { txById[t.id] = t }

        // Categories — upsert + slug map.
        var catBySlug: [String: Category] = [:]
        var remoteCatIds = Set<UUID>()
        for dto in cats {
            remoteCatIds.insert(dto.id)
            let resolved: Category
            if let local = catById[dto.id] {
                apply(dto, to: local)
                resolved = local
            } else {
                let made = build(dto)
                modelContext.insert(made)
                catById[dto.id] = made
                resolved = made
            }
            if let slug = resolved.slug, !slug.isEmpty { catBySlug[slug] = resolved }
        }

        // Transactions — upsert, skipping unchanged rows.
        var remoteTxIds = Set<UUID>()
        for dto in txs {
            remoteTxIds.insert(dto.id)
            let cat = catBySlug[dto.categorySlug]
            if let local = txById[dto.id] {
                if let ru = dto.updatedAt, abs(local.updatedAt.timeIntervalSince(ru)) < 0.001 {
                    if local.category !== cat { local.category = cat }   // only if link differs
                } else {
                    apply(dto, to: local)
                    local.category = cat
                }
            } else {
                let made = build(dto)
                made.category = cat
                modelContext.insert(made)
            }
        }

        // Reconcile deletes (server is source of truth) — local cache only.
        for c in localCats where c.userId == userId && !remoteCatIds.contains(c.id) {
            modelContext.delete(c)
        }
        for t in localTxs where t.userId == userId && !remoteTxIds.contains(t.id) {
            modelContext.delete(t)
        }

        try? modelContext.save()
    }

    /// Live category deltas from the snapshot listener.
    func applyCategoryChanges(_ changes: [SyncChange<CatDTO>]) {
        guard !changes.isEmpty else { return }
        for change in changes {
            switch change {
            case .upsert(let dto):
                if let local = fetchCategory(dto.id) {
                    apply(dto, to: local)
                } else {
                    modelContext.insert(build(dto))
                }
            case .remove(let id):
                if let local = fetchCategory(id) { modelContext.delete(local) }
            }
        }
        try? modelContext.save()
    }

    /// Live transaction deltas from the snapshot listener.
    func applyTransactionChanges(_ changes: [SyncChange<TxDTO>]) {
        guard !changes.isEmpty else { return }

        // slug → Category for relinking (first-write-wins on duplicate slugs).
        let allCats = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        var catBySlug: [String: Category] = [:]
        for c in allCats where c.slug?.isEmpty == false {
            if let s = c.slug, catBySlug[s] == nil { catBySlug[s] = c }
        }

        // Large batch (first snapshot) → bulk id-map; small live edits → per-id.
        let useMap = changes.count > 30
        var txById: [UUID: Transaction] = [:]
        if useMap {
            for t in (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? [] { txById[t.id] = t }
        }
        func local(_ id: UUID) -> Transaction? { useMap ? txById[id] : fetchTransaction(id) }

        for change in changes {
            switch change {
            case .upsert(let dto):
                let cat = catBySlug[dto.categorySlug]
                if let row = local(dto.id) {
                    if let ru = dto.updatedAt, abs(row.updatedAt.timeIntervalSince(ru)) < 0.001 {
                        if row.category !== cat { row.category = cat }
                    } else {
                        apply(dto, to: row)
                        row.category = cat
                    }
                } else {
                    let made = build(dto)
                    made.category = cat
                    modelContext.insert(made)
                    if useMap { txById[dto.id] = made }
                }
            case .remove(let id):
                if let row = local(id) { modelContext.delete(row) }
            }
        }
        try? modelContext.save()
    }

    // MARK: - Lookups

    private func fetchCategory(_ id: UUID) -> Category? {
        (try? modelContext.fetch(FetchDescriptor<Category>(predicate: #Predicate { $0.id == id })))?.first
    }
    private func fetchTransaction(_ id: UUID) -> Transaction? {
        (try? modelContext.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == id })))?.first
    }

    // MARK: - Build / apply

    private func build(_ d: CatDTO) -> Category {
        Category(
            id: d.id, userId: d.userId, name: d.name, slug: d.slug,
            type: TransactionType(rawValue: d.type) ?? .expense,
            iconName: d.iconName, colorHex: d.colorHex,
            isDefault: d.isDefault, sortOrder: d.sortOrder
        )
    }
    private func apply(_ d: CatDTO, to c: Category) {
        c.name = d.name
        c.slug = d.slug
        if let t = TransactionType(rawValue: d.type) { c.type = t }
        c.iconName = d.iconName
        c.colorHex = d.colorHex
        c.isDefault = d.isDefault
        c.sortOrder = d.sortOrder
    }
    private func build(_ d: TxDTO) -> Transaction {
        let t = Transaction(
            id: d.id, userId: d.userId,
            type: TransactionType(rawValue: d.type) ?? .expense,
            amount: Decimal(d.amount), currency: d.currency, note: d.note,
            date: d.date, status: TransactionStatus(rawValue: d.status) ?? .completed
        )
        if let u = d.updatedAt { t.updatedAt = u }
        if let c = d.createdAt { t.createdAt = c }
        return t
    }
    private func apply(_ d: TxDTO, to t: Transaction) {
        if let ty = TransactionType(rawValue: d.type) { t.type = ty }
        t.amount = Decimal(d.amount)
        t.currency = d.currency
        t.note = d.note
        t.date = d.date
        if let s = TransactionStatus(rawValue: d.status) { t.status = s }
        if let u = d.updatedAt { t.updatedAt = u }
    }
}
