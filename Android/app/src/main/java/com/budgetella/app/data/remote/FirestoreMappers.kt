package com.budgetella.app.data.remote

import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.model.Money
import com.budgetella.app.data.model.TransactionStatus
import com.budgetella.app.data.model.TransactionType
import com.google.firebase.Timestamp
import java.math.BigDecimal
import java.util.UUID

/**
 * Document ↔ Entity mappers for Firestore sync.
 *
 * Cross-platform contract (matches iOS FirestoreService.swift exactly):
 *  - amount        Double, major units (12.50 — NOT minor-units 1250)
 *  - date          Firestore Timestamp
 *  - type / status Strings ("income" / "expense" / …)
 *  - categorySlug  String (not a Firestore reference) — we look the local
 *                  category up by slug on the read path
 *  - "" empty string is preferred over null for optional Strings since the
 *    iOS doc shape uses "" defaults
 */
internal object FirestoreMappers {

    // ── Transaction ────────────────────────────────────────────────────────

    fun transactionToDoc(entity: TransactionEntity, categorySlug: String?): Map<String, Any?> = mapOf(
        "id"                 to entity.id,
        "userId"             to entity.userId,
        "type"               to entity.typeRaw,
        "amount"             to Money(entity.amount).toBigDecimal().toDouble(),
        "currency"           to entity.currency,
        "note"               to entity.note,
        "categorySlug"       to (categorySlug ?: ""),
        "date"               to Timestamp(entity.date / 1000, ((entity.date % 1000) * 1_000_000).toInt()),
        "status"             to entity.statusRaw,
        "isRecurring"        to entity.isRecurring,
        "recurringInterval"  to (entity.recurringIntervalRaw ?: ""),
        "createdAt"          to Timestamp(entity.createdAt / 1000, ((entity.createdAt % 1000) * 1_000_000).toInt()),
        "updatedAt"          to Timestamp(entity.updatedAt / 1000, ((entity.updatedAt % 1000) * 1_000_000).toInt()),
    )

    /**
     * Reverse mapping. `categoryIdBySlug` looks up the local category row so
     * we can populate the FK; if the slug is unknown (e.g. user has deleted
     * the category on this device) the FK is left null — matches the iOS
     * SET NULL delete rule.
     */
    fun docToTransaction(
        doc: Map<String, Any?>,
        categoryIdBySlug: Map<String, String>,
    ): TransactionEntity? {
        val id = doc["id"] as? String ?: return null
        val userId = doc["userId"] as? String ?: return null
        val amountDouble = (doc["amount"] as? Number)?.toDouble() ?: 0.0
        val amountMinor = Money.fromMajor(BigDecimal.valueOf(amountDouble)).minorUnits

        val slug = (doc["categorySlug"] as? String)?.takeIf { it.isNotBlank() }
        val categoryId = slug?.let(categoryIdBySlug::get)

        return TransactionEntity(
            id = id,
            userId = userId,
            typeRaw = (doc["type"] as? String) ?: TransactionType.Expense.raw,
            amount = amountMinor,
            currency = (doc["currency"] as? String) ?: "TRY",
            note = (doc["note"] as? String) ?: "",
            date = (doc["date"] as? Timestamp)?.toDate()?.time ?: System.currentTimeMillis(),
            statusRaw = (doc["status"] as? String) ?: TransactionStatus.Completed.raw,
            isRecurring = doc["isRecurring"] as? Boolean ?: false,
            recurringIntervalRaw = (doc["recurringInterval"] as? String)?.takeIf { it.isNotBlank() },
            recurringEndDate = (doc["recurringEndDate"] as? Timestamp)?.toDate()?.time,
            originalTransactionId = (doc["originalTransactionId"] as? String)?.takeIf { it.isNotBlank() },
            categoryId = categoryId,
            createdAt = (doc["createdAt"] as? Timestamp)?.toDate()?.time ?: System.currentTimeMillis(),
            updatedAt = (doc["updatedAt"] as? Timestamp)?.toDate()?.time ?: System.currentTimeMillis(),
        )
    }

    // ── Category ───────────────────────────────────────────────────────────

    fun categoryToDoc(entity: CategoryEntity): Map<String, Any?> = mapOf(
        "id"        to entity.id,
        "userId"    to entity.userId,
        "name"      to entity.name,
        "slug"      to (entity.slug ?: ""),
        "type"      to entity.typeRaw,
        "iconName"  to entity.iconName,
        "colorHex"  to entity.colorHex,
        "isDefault" to entity.isDefault,
        "sortOrder" to entity.sortOrder,
    )

    fun docToCategory(doc: Map<String, Any?>): CategoryEntity? {
        val id = doc["id"] as? String ?: return null
        val userId = doc["userId"] as? String ?: return null
        return CategoryEntity(
            id = id,
            userId = userId,
            name = (doc["name"] as? String) ?: "",
            slug = (doc["slug"] as? String)?.takeIf { it.isNotBlank() },
            typeRaw = (doc["type"] as? String) ?: TransactionType.Expense.raw,
            iconName = (doc["iconName"] as? String) ?: "tag",
            colorHex = (doc["colorHex"] as? String) ?: "#6366f1",
            isDefault = doc["isDefault"] as? Boolean ?: false,
            sortOrder = (doc["sortOrder"] as? Number)?.toInt() ?: 0,
            createdAt = System.currentTimeMillis(),
        )
    }
}

/** Convenience UUID generator used when creating fresh records. */
internal fun newId(): String = UUID.randomUUID().toString()
