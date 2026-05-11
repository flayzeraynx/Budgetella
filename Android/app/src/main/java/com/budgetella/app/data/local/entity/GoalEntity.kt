package com.budgetella.app.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.budgetella.app.data.model.GoalTemplate

/**
 * Savings goal — port of iOS Goal.swift.
 *
 * Both targetAmount and currentAmount are stored in minor-units. currentAmount
 * is updated manually by the user in V1 (we don't auto-aggregate transactions
 * into goal contributions — same as iOS).
 *
 * isArchived is reserved for V1.1+ soft-delete; in V1 we hard-delete.
 */
@Entity(
    tableName = "goals",
    indices = [Index("userId")]
)
data class GoalEntity(
    @PrimaryKey val id: String,
    val userId: String,

    val name: String,
    val targetAmount: Long,
    val currentAmount: Long = 0L,
    val currency: String = "TRY",

    /** Epoch millis. */
    val deadline: Long? = null,
    val iconName: String,
    /** [GoalTemplate.raw] or null for fully custom goals. */
    @ColumnInfo(name = "templateSlug") val templateSlugRaw: String? = null,
    val isArchived: Boolean = false,

    val createdAt: Long,
    val updatedAt: Long,
) {
    val template: GoalTemplate? get() = GoalTemplate.fromRaw(templateSlugRaw)

    /** 0.0..1.0, clamped. */
    val progress: Double
        get() = if (targetAmount <= 0) 0.0 else (currentAmount.toDouble() / targetAmount).coerceIn(0.0, 1.0)

    val isCompleted: Boolean get() = currentAmount >= targetAmount

    val remaining: Long get() = (targetAmount - currentAmount).coerceAtLeast(0L)
}
