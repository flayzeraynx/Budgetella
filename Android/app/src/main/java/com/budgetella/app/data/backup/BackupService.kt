package com.budgetella.app.data.backup

import com.budgetella.app.data.local.dao.CategoryDao
import com.budgetella.app.data.local.dao.TransactionDao
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.model.Money
import com.budgetella.app.data.model.TransactionStatus
import com.budgetella.app.data.model.TransactionType
import com.budgetella.app.data.prefs.UserPrefs
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * JSON backup port of iOS BackupExportService/BackupImportService.
 *
 * Wire shape (schemaVersion 1):
 *   {
 *     "schemaVersion": 1,
 *     "exportedAt":   ISO8601 instant,
 *     "userId":       UID,
 *     "transactions": [BackupTransaction],
 *     "categories":   [BackupCategory]
 *   }
 *
 * Cross-platform contract notes:
 *  - Amounts are Double major-units (12.50 NOT 1250) — round-tripped through
 *    [Money.fromMajor] / [Money.toBigDecimal] so we don't lose precision.
 *  - Dates are ISO8601 strings via [Instant.toString] — millis are epoch UTC
 *    so import/export is timezone-stable.
 *  - Import is idempotent: rows with an id already present in Room are
 *    *skipped* (not overwritten) — preserves any local edits made since the
 *    backup was taken.
 *
 * NOTE: [UserPrefs] is injected so the service is self-contained when called
 * from a worker / non-UI path, but the typical caller (the BackupLaunchers
 * Compose helper) supplies the userId explicitly.
 */
@Singleton
class BackupService @Inject constructor(
    private val transactionDao: TransactionDao,
    private val categoryDao: CategoryDao,
    @Suppress("unused") private val userPrefs: UserPrefs,
) {

    private val json = Json {
        ignoreUnknownKeys = true
        prettyPrint = true
        encodeDefaults = true
    }

    /** Serialise the active user's transactions + categories to a JSON document. */
    suspend fun export(userId: String): String {
        val transactions = transactionDao.listRange(
            userId = userId,
            startMillis = Long.MIN_VALUE,
            endMillis = Long.MAX_VALUE,
        )
        val categories = categoryDao.listByUser(userId)
        val idToSlug: Map<String, String?> = categories.associate { it.id to it.slug }

        val doc = BackupDocument(
            schemaVersion = SCHEMA_VERSION,
            exportedAt = Instant.now().toString(),
            userId = userId,
            transactions = transactions.map { it.toWire(idToSlug) },
            categories = categories.map { it.toWire() },
        )
        return json.encodeToString(doc)
    }

    /**
     * Read a JSON document and upsert any rows whose ids aren't already
     * present. Returns a tally so the UI can show "N imported, M skipped".
     *
     * Categories are tied to userId — incoming rows for a *different* user
     * are rewritten so they belong to the active user (matches iOS behaviour
     * when restoring a backup on a new account).
     */
    suspend fun import(json: String, userId: String): ImportResult {
        val doc = this.json.decodeFromString<BackupDocument>(json)

        val now = System.currentTimeMillis()
        var categoriesCreated = 0

        // Categories first — transactions depend on them via foreign key.
        // Map "incoming slug -> existing id" so transactions can be rewired
        // if the local copy has a different UUID for the same default slug.
        val slugToLocalId = mutableMapOf<String, String>()
        for (incoming in doc.categories) {
            val slug = incoming.slug
            // 1. Honour any existing row with the same id verbatim.
            val byId = categoryDao.findById(incoming.id)
            if (byId != null) {
                if (slug != null) slugToLocalId[slug] = byId.id
                continue
            }
            // 2. Default categories: dedupe by slug so we don't double-seed.
            if (slug != null) {
                val bySlug = categoryDao.findBySlug(userId, slug)
                if (bySlug != null) {
                    slugToLocalId[slug] = bySlug.id
                    continue
                }
            }
            val row = incoming.toEntity(userId = userId, fallbackCreatedAt = now)
            categoryDao.upsert(row)
            categoriesCreated += 1
            if (slug != null) slugToLocalId[slug] = row.id
        }

        var imported = 0
        var skipped = 0
        for (incoming in doc.transactions) {
            // Existing row → skip (don't clobber local edits).
            if (transactionDao.findById(incoming.id) != null) {
                skipped += 1
                continue
            }
            // Resolve categoryId: prefer the slug→local-id map (handles the
            // "same default category, different UUID" case), fall back to the
            // raw value from the backup.
            val resolvedCategoryId = incoming.categorySlug
                ?.let { slugToLocalId[it] }
                ?: incoming.categoryId

            transactionDao.upsert(
                incoming.toEntity(
                    userId = userId,
                    categoryIdOverride = resolvedCategoryId,
                    fallbackTimestamp = now,
                )
            )
            imported += 1
        }

        return ImportResult(
            transactionsImported = imported,
            transactionsSkipped = skipped,
            categoriesCreated = categoriesCreated,
        )
    }

    companion object {
        const val SCHEMA_VERSION: Int = 1
    }

    // ── Wire shape ──────────────────────────────────────────────────────────

    @Serializable
    private data class BackupDocument(
        val schemaVersion: Int = SCHEMA_VERSION,
        val exportedAt: String,
        val userId: String,
        val transactions: List<BackupTransaction> = emptyList(),
        val categories: List<BackupCategory> = emptyList(),
    )

    @Serializable
    private data class BackupTransaction(
        val id: String,
        val type: String,
        val amount: Double,
        val currency: String = "TRY",
        val note: String = "",
        val categorySlug: String? = null,
        val categoryId: String? = null,
        val date: String,
        val status: String = "completed",
        val isRecurring: Boolean = false,
        val recurringInterval: String? = null,
        val createdAt: String? = null,
        val updatedAt: String? = null,
    )

    @Serializable
    private data class BackupCategory(
        val id: String,
        val name: String,
        val slug: String? = null,
        val type: String,
        val iconName: String = "tag",
        val colorHex: String = "#6366f1",
        val isDefault: Boolean = false,
        val sortOrder: Int = 0,
    )

    // ── Mappers ─────────────────────────────────────────────────────────────

    private fun TransactionEntity.toWire(idToSlug: Map<String, String?>): BackupTransaction {
        val major = Money(amount).toBigDecimal().toDouble()
        return BackupTransaction(
            id = id,
            type = typeRaw,
            amount = major,
            currency = currency,
            note = note,
            categorySlug = categoryId?.let { idToSlug[it] },
            categoryId = categoryId,
            date = Instant.ofEpochMilli(date).toString(),
            status = statusRaw,
            isRecurring = isRecurring,
            recurringInterval = recurringIntervalRaw,
            createdAt = Instant.ofEpochMilli(createdAt).toString(),
            updatedAt = Instant.ofEpochMilli(updatedAt).toString(),
        )
    }

    private fun CategoryEntity.toWire(): BackupCategory =
        BackupCategory(
            id = id,
            name = name,
            slug = slug,
            type = typeRaw,
            iconName = iconName,
            colorHex = colorHex,
            isDefault = isDefault,
            sortOrder = sortOrder,
        )

    private fun BackupTransaction.toEntity(
        userId: String,
        categoryIdOverride: String?,
        fallbackTimestamp: Long,
    ): TransactionEntity {
        val parsedDate = parseInstantMillis(date) ?: fallbackTimestamp
        return TransactionEntity(
            id = id.ifBlank { UUID.randomUUID().toString() },
            userId = userId,
            typeRaw = TransactionType.fromRaw(type).raw,
            amount = Money.fromMajor(BigDecimal.valueOf(amount)).minorUnits,
            currency = currency,
            note = note,
            date = parsedDate,
            statusRaw = TransactionStatus.fromRaw(status).raw,
            isRecurring = isRecurring,
            recurringIntervalRaw = recurringInterval,
            recurringEndDate = null,
            originalTransactionId = null,
            categoryId = categoryIdOverride,
            createdAt = parseInstantMillis(createdAt) ?: fallbackTimestamp,
            updatedAt = parseInstantMillis(updatedAt) ?: fallbackTimestamp,
        )
    }

    private fun BackupCategory.toEntity(
        userId: String,
        fallbackCreatedAt: Long,
    ): CategoryEntity =
        CategoryEntity(
            id = id.ifBlank { UUID.randomUUID().toString() },
            userId = userId,
            name = name,
            slug = slug,
            typeRaw = TransactionType.fromRaw(type).raw,
            iconName = iconName,
            colorHex = colorHex,
            isDefault = isDefault,
            sortOrder = sortOrder,
            createdAt = fallbackCreatedAt,
        )

    private fun parseInstantMillis(value: String?): Long? {
        if (value.isNullOrBlank()) return null
        return runCatching { Instant.parse(value).toEpochMilli() }.getOrNull()
    }
}

/** Counts returned to the UI after an import run. */
data class ImportResult(
    val transactionsImported: Int,
    val transactionsSkipped: Int,
    val categoriesCreated: Int,
)
