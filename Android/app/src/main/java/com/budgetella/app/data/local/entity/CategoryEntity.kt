package com.budgetella.app.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.budgetella.app.data.model.CategorySlug
import com.budgetella.app.data.model.TransactionType

/**
 * Income/expense category — port of iOS Category.swift @Model.
 *
 * Default categories have `slug = CategorySlug.raw`; custom (premium) ones
 * leave it null and use [name] verbatim. Display name is resolved at the UI
 * layer via the same i18n key pattern iOS uses (`category.slug.<slug>` →
 * res/values{,-tr}/strings.xml).
 */
@Entity(
    tableName = "categories",
    indices = [
        Index("userId"),
        Index(value = ["userId", "sortOrder"]),
        Index(value = ["userId", "slug"], unique = false)
    ]
)
data class CategoryEntity(
    @PrimaryKey val id: String,
    val userId: String,

    /**
     * For default categories this is the seeded Turkish label (e.g. "Yiyecek")
     * — kept around as a fallback if the i18n lookup fails. For custom
     * categories this is the user's free-text input.
     */
    val name: String,

    /** [CategorySlug.raw] for default categories; null for custom ones. */
    val slug: String? = null,

    /** [TransactionType.raw] — "income" / "expense". */
    @ColumnInfo(name = "type") val typeRaw: String,

    /** SF Symbol name on iOS; the Android UI maps these to Material icons. */
    val iconName: String = "tag",

    /** "#RRGGBB" — same hex used on iOS so charts stay colour-consistent. */
    val colorHex: String = "#6366f1",

    val isDefault: Boolean = false,
    val sortOrder: Int = 0,

    val createdAt: Long,
) {
    val type: TransactionType get() = TransactionType.fromRaw(typeRaw)
    val categorySlug: CategorySlug? get() = CategorySlug.fromRaw(slug)
}
