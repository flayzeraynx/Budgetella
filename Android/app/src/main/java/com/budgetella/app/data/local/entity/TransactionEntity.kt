package com.budgetella.app.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.budgetella.app.data.model.RecurringInterval
import com.budgetella.app.data.model.TransactionStatus
import com.budgetella.app.data.model.TransactionType

/**
 * Single transaction row — port of iOS Transaction.swift @Model.
 *
 * Storage decisions:
 *  - id is a String UUID (matches Firestore document IDs the iOS app already writes)
 *  - amount is Long minor-units (kuruş/cents) — wrapped by [com.budgetella.app.data.model.Money]
 *  - dates are epoch millis (Long) — easy for Room indexes + serialisation
 *  - enum fields stored as their `raw` string for cross-platform compatibility
 *
 * Foreign-key on categoryId uses ON DELETE SET NULL so deleting a category
 * preserves the transaction history (matches iOS deleteRule: .nullify).
 */
@Entity(
    tableName = "transactions",
    foreignKeys = [
        ForeignKey(
            entity = CategoryEntity::class,
            parentColumns = ["id"],
            childColumns = ["categoryId"],
            onDelete = ForeignKey.SET_NULL
        )
    ],
    indices = [
        Index("userId"),
        Index("categoryId"),
        Index("date"),
        Index(value = ["userId", "date"], orders = [Index.Order.ASC, Index.Order.DESC])
    ]
)
data class TransactionEntity(
    @PrimaryKey val id: String,
    val userId: String,

    /** [TransactionType.raw] — "income" / "expense". */
    @ColumnInfo(name = "type") val typeRaw: String,

    /** Minor-units. 1 ₺ = 100. Always non-negative; sign comes from `type`. */
    val amount: Long,

    val currency: String = "TRY",
    val note: String,
    /** Epoch millis. */
    val date: Long,

    /** [TransactionStatus.raw] — "completed" / "pending" / "planned". */
    @ColumnInfo(name = "status") val statusRaw: String = TransactionStatus.Completed.raw,

    val isRecurring: Boolean = false,
    /** [RecurringInterval.raw], null when not recurring. */
    @ColumnInfo(name = "recurringInterval") val recurringIntervalRaw: String? = null,
    /** Epoch millis or null. */
    val recurringEndDate: Long? = null,
    /** Points to the parent template Transaction.id when this is an instance. */
    val originalTransactionId: String? = null,

    /** Foreign key into categories.id. NULL when category was deleted. */
    val categoryId: String? = null,

    val createdAt: Long,
    val updatedAt: Long,
) {
    val type: TransactionType get() = TransactionType.fromRaw(typeRaw)
    val status: TransactionStatus get() = TransactionStatus.fromRaw(statusRaw)
    val recurringInterval: RecurringInterval? get() = RecurringInterval.fromRaw(recurringIntervalRaw)
}
