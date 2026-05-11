package com.budgetella.app.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.budgetella.app.data.model.SubscriptionType

/**
 * Local cache of the currently signed-in Firebase user — port of iOS User.swift.
 *
 * Source-of-truth: Firestore `users/{uid}`. Mirrored here so the UI can render
 * profile + premium state without a network round-trip on every screen.
 *
 * Roles is a comma-separated string in the column (TypeConverter handles
 * List<String> ↔ String conversion in [com.budgetella.app.data.local.Converters]).
 */
@Entity(tableName = "users")
data class UserEntity(
    /** Firebase Auth UID. */
    @PrimaryKey val uid: String,

    val email: String,
    val displayName: String? = null,
    val photoURL: String? = null,

    val isPremium: Boolean = false,
    /** [SubscriptionType.raw] — "none" / "monthly" / "yearly" / "lifetime". */
    @ColumnInfo(name = "subscriptionType") val subscriptionTypeRaw: String = SubscriptionType.None.raw,
    val subscriptionId: String? = null,
    /** Epoch millis or null. */
    val subscriptionEndDate: Long? = null,
    /** "active" / "canceled" / "past_due" — free-form to match Stripe webhook. */
    val subscriptionStatus: String? = null,
    val customerId: String? = null,

    /** Comma-separated. "admin" included if the user has the admin role. */
    val roles: List<String> = emptyList(),

    val dailyStreakCount: Int = 0,
    val streakStartedAt: Long? = null,
    /** Date-only (start of day, epoch millis) so streak math is timezone-stable. */
    val lastActiveDate: Long? = null,
    val lastSyncedAt: Long? = null,

    val createdAt: Long,
    val updatedAt: Long,
) {
    val subscriptionType: SubscriptionType
        get() = SubscriptionType.fromRaw(subscriptionTypeRaw)

    val isAdmin: Boolean get() = roles.any { it.equals("admin", ignoreCase = true) }

    fun hasActivePremium(now: Long = System.currentTimeMillis()): Boolean {
        if (!isPremium) return false
        val end = subscriptionEndDate ?: return subscriptionType == SubscriptionType.Lifetime
        return end >= now
    }
}
