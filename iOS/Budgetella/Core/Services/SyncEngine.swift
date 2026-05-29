//
//  SyncEngine.swift
//  Budgetella
//
//  Background SwiftData merge. Runs ALL Firestore→SwiftData writes on a private
//  ModelContext created INSIDE a detached background Task — guaranteeing the
//  main thread is never blocked (the @ModelActor approach ran on the caller's
//  thread, i.e. main, so it didn't actually offload).
//
//  FirestoreService parses Firestore documents into the Sendable DTOs below
//  (it owns the FirebaseFirestore import); this engine only touches Sendable
//  value types + @Model objects local to its background context.
//
//  Source of truth is Firestore; local SwiftData is a rebuildable cache.
//  reconcile() deletes only LOCAL rows the server no longer has — it never
//  pushes deletes to Firestore, so a bug here can drop only the local cache
//  (recoverable by re-sync), never the cloud copy.
//

import Foundation
import SwiftData

// MARK: - Sendable DTOs (safe to cross the Task boundary)

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

// MARK: - Background merge

enum SyncEngine {

    /// Initial full pull. Upsert + content-skip (no write when unchanged) +
    /// delete-reconcile. Runs entirely on a background thread.
    static func reconcile(container: ModelContainer, userId: String, cats: [CatDTO], txs: [TxDTO]) async {
        await Task.detached(priority: .utility) {
            EntryPerf.event("reconcile EXECUTING — main=\(Self.isMainThread()), cats=\(cats.count) txs=\(txs.count)")
            let ctx = ModelContext(container)

            let localCats = (try? ctx.fetch(FetchDescriptor<Category>())) ?? []
            let localTxs = (try? ctx.fetch(FetchDescriptor<Transaction>())) ?? []

            // Privacy guard — drop rows from other accounts.
            for c in localCats where c.userId != userId { ctx.delete(c) }
            for t in localTxs where t.userId != userId { ctx.delete(t) }

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
                    Self.apply(dto, to: local)
                    resolved = local
                } else {
                    let made = Self.build(dto)
                    ctx.insert(made)
                    catById[dto.id] = made
                    resolved = made
                }
                if let slug = resolved.slug, !slug.isEmpty { catBySlug[slug] = resolved }
            }

            // Transactions — upsert, content-skip unchanged rows.
            var remoteTxIds = Set<UUID>()
            for dto in txs {
                remoteTxIds.insert(dto.id)
                if let local = txById[dto.id] {
                    if !Self.matches(dto, local) {
                        Self.apply(dto, to: local)
                        local.category = catBySlug[dto.categorySlug]
                    }
                } else {
                    let made = Self.build(dto)
                    made.category = catBySlug[dto.categorySlug]
                    ctx.insert(made)
                }
            }

            // Reconcile deletes (local cache only).
            for c in localCats where c.userId == userId && !remoteCatIds.contains(c.id) { ctx.delete(c) }
            for t in localTxs where t.userId == userId && !remoteTxIds.contains(t.id) { ctx.delete(t) }

            try? ctx.save()
        }.value
    }

    /// Live category deltas from the snapshot listener.
    static func applyCategoryChanges(container: ModelContainer, _ changes: [SyncChange<CatDTO>]) async {
        guard !changes.isEmpty else { return }
        await Task.detached(priority: .utility) {
            let ctx = ModelContext(container)
            for change in changes {
                switch change {
                case .upsert(let dto):
                    if let local = Self.fetchCategory(dto.id, ctx) { Self.apply(dto, to: local) }
                    else { ctx.insert(Self.build(dto)) }
                case .remove(let id):
                    if let local = Self.fetchCategory(id, ctx) { ctx.delete(local) }
                }
            }
            try? ctx.save()
        }.value
    }

    /// Live transaction deltas from the snapshot listener.
    static func applyTransactionChanges(container: ModelContainer, _ changes: [SyncChange<TxDTO>]) async {
        guard !changes.isEmpty else { return }
        await Task.detached(priority: .utility) {
            let ctx = ModelContext(container)

            let allCats = (try? ctx.fetch(FetchDescriptor<Category>())) ?? []
            var catBySlug: [String: Category] = [:]
            for c in allCats where c.slug?.isEmpty == false {
                if let s = c.slug, catBySlug[s] == nil { catBySlug[s] = c }
            }

            let useMap = changes.count > 30
            var txById: [UUID: Transaction] = [:]
            if useMap {
                for t in (try? ctx.fetch(FetchDescriptor<Transaction>())) ?? [] { txById[t.id] = t }
            }

            for change in changes {
                switch change {
                case .upsert(let dto):
                    let row = useMap ? txById[dto.id] : Self.fetchTransaction(dto.id, ctx)
                    if let row {
                        if !Self.matches(dto, row) {
                            Self.apply(dto, to: row)
                            row.category = catBySlug[dto.categorySlug]
                        }
                    } else {
                        let made = Self.build(dto)
                        made.category = catBySlug[dto.categorySlug]
                        ctx.insert(made)
                        if useMap { txById[dto.id] = made }
                    }
                case .remove(let id):
                    let row = useMap ? txById[id] : Self.fetchTransaction(id, ctx)
                    if let row { ctx.delete(row) }
                }
            }
            try? ctx.save()
        }.value
    }

    // MARK: - Helpers (pure / context-scoped)

    /// Synchronous wrapper — `Thread.isMainThread` is unavailable directly in
    /// async contexts. Temporary, for the off-main verification probe.
    private static func isMainThread() -> Bool { Thread.isMainThread }

    private static func fetchCategory(_ id: UUID, _ ctx: ModelContext) -> Category? {
        (try? ctx.fetch(FetchDescriptor<Category>(predicate: #Predicate { $0.id == id })))?.first
    }
    private static func fetchTransaction(_ id: UUID, _ ctx: ModelContext) -> Transaction? {
        (try? ctx.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == id })))?.first
    }

    /// True when a local transaction already equals the remote doc — skip write.
    private static func matches(_ d: TxDTO, _ t: Transaction) -> Bool {
        guard
            t.type.rawValue == d.type,
            t.note == d.note,
            t.currency == d.currency,
            t.status.rawValue == d.status,
            (t.category?.slug ?? "") == d.categorySlug,
            abs(t.date.timeIntervalSince(d.date)) < 1.0
        else { return false }
        let localAmt = NSDecimalNumber(decimal: t.amount).doubleValue
        return abs(localAmt - d.amount) < 0.001
    }

    private static func build(_ d: CatDTO) -> Category {
        Category(
            id: d.id, userId: d.userId, name: d.name, slug: d.slug,
            type: TransactionType(rawValue: d.type) ?? .expense,
            iconName: d.iconName, colorHex: d.colorHex,
            isDefault: d.isDefault, sortOrder: d.sortOrder
        )
    }
    private static func apply(_ d: CatDTO, to c: Category) {
        c.name = d.name
        c.slug = d.slug
        if let t = TransactionType(rawValue: d.type) { c.type = t }
        c.iconName = d.iconName
        c.colorHex = d.colorHex
        c.isDefault = d.isDefault
        c.sortOrder = d.sortOrder
    }
    private static func build(_ d: TxDTO) -> Transaction {
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
    private static func apply(_ d: TxDTO, to t: Transaction) {
        if let ty = TransactionType(rawValue: d.type) { t.type = ty }
        t.amount = Decimal(d.amount)
        t.currency = d.currency
        t.note = d.note
        t.date = d.date
        if let s = TransactionStatus(rawValue: d.status) { t.status = s }
        if let u = d.updatedAt { t.updatedAt = u }
    }
}
