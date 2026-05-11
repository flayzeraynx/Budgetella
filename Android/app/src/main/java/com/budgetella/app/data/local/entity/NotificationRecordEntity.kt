package com.budgetella.app.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * Mirrored FCM payload — port of iOS NotificationRecord.swift.
 *
 * Persists every incoming push so the user can read history in the inbox even
 * after the system tray clears. `kindRaw` parallels the iOS NotificationKind
 * enum values (weekly_digest / budget_alert / anomaly / achievement /
 * goal_milestone / system_message).
 */
@Entity(
    tableName = "notification_records",
    indices = [Index("userId"), Index(value = ["userId", "createdAt"])]
)
data class NotificationRecordEntity(
    @PrimaryKey val id: String,
    val userId: String,
    @ColumnInfo(name = "kind") val kindRaw: String,
    val title: String,
    val body: String,
    val deepLink: String? = null,
    val isRead: Boolean = false,
    val createdAt: Long,
)

enum class NotificationKind(val raw: String) {
    WeeklyDigest("weekly_digest"),
    BudgetAlert("budget_alert"),
    Anomaly("anomaly"),
    Achievement("achievement"),
    GoalMilestone("goal_milestone"),
    SystemMessage("system_message");

    companion object {
        fun fromRaw(raw: String?): NotificationKind =
            entries.firstOrNull { it.raw == raw } ?: SystemMessage
    }
}
