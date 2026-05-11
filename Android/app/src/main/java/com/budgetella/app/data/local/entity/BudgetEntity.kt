package com.budgetella.app.data.local.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.budgetella.app.data.model.CategorySlug

/**
 * Monthly category budget — port of iOS Budget.swift.
 *
 * Reference is by [CategorySlug.raw], NOT a foreign key into [CategoryEntity].
 * That's deliberate: a user can delete a category without losing the budget
 * record they set against it (iOS uses the same approach). Custom categories
 * can't have budgets in V1 because they have no slug.
 *
 * No DB-level uniqueness on (userId, categorySlug, month, year) — the iOS app
 * enforces "one budget per (slug, month, year)" in BudgetService and we'll do
 * the same here when M4 lands.
 */
@Entity(
    tableName = "budgets",
    indices = [
        Index("userId"),
        Index(value = ["userId", "year", "month"])
    ]
)
data class BudgetEntity(
    @PrimaryKey val id: String,
    val userId: String,

    /** [CategorySlug.raw] — references but does not foreign-key into categories. */
    val categorySlug: String,

    /** Limit, stored in minor-units. */
    val amount: Long,
    val currency: String = "TRY",

    /** 1..12. */
    val month: Int,
    val year: Int,

    val createdAt: Long,
    val updatedAt: Long,
) {
    val slug: CategorySlug? get() = CategorySlug.fromRaw(categorySlug)

    /** "YYYY-MM" — handy as a Map key. */
    val monthKey: String get() = "%04d-%02d".format(year, month)
}
