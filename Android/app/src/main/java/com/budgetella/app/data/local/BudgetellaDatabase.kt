package com.budgetella.app.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.budgetella.app.data.local.dao.AppSettingsDao
import com.budgetella.app.data.local.dao.BudgetDao
import com.budgetella.app.data.local.dao.CategoryDao
import com.budgetella.app.data.local.dao.GoalDao
import com.budgetella.app.data.local.dao.NotificationRecordDao
import com.budgetella.app.data.local.dao.TransactionDao
import com.budgetella.app.data.local.dao.UserDao
import com.budgetella.app.data.local.entity.AppSettingsEntity
import com.budgetella.app.data.local.entity.BudgetEntity
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.local.entity.GoalEntity
import com.budgetella.app.data.local.entity.NotificationRecordEntity
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.local.entity.UserEntity

/**
 * Room database — seven entities, version 2.
 *
 * v1 → v2 added `notification_records` (M7 push inbox). Achievement and
 * SubscriptionRecord stay deferred — they land with M8 + a future v3 bump.
 */
@Database(
    entities = [
        TransactionEntity::class,
        CategoryEntity::class,
        UserEntity::class,
        AppSettingsEntity::class,
        BudgetEntity::class,
        GoalEntity::class,
        NotificationRecordEntity::class,
    ],
    version = 2,
    exportSchema = true,
)
@TypeConverters(Converters::class)
abstract class BudgetellaDatabase : RoomDatabase() {

    abstract fun transactionDao(): TransactionDao
    abstract fun categoryDao(): CategoryDao
    abstract fun userDao(): UserDao
    abstract fun appSettingsDao(): AppSettingsDao
    abstract fun budgetDao(): BudgetDao
    abstract fun goalDao(): GoalDao
    abstract fun notificationRecordDao(): NotificationRecordDao

    companion object {
        const val DATABASE_NAME: String = "budgetella.db"

        /** v1 → v2 — adds the notification_records table. */
        val MIGRATION_1_2: Migration = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `notification_records` (
                        `id` TEXT NOT NULL,
                        `userId` TEXT NOT NULL,
                        `kind` TEXT NOT NULL,
                        `title` TEXT NOT NULL,
                        `body` TEXT NOT NULL,
                        `deepLink` TEXT,
                        `isRead` INTEGER NOT NULL,
                        `createdAt` INTEGER NOT NULL,
                        PRIMARY KEY(`id`)
                    )
                    """.trimIndent()
                )
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_notification_records_userId` ON `notification_records` (`userId`)")
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_notification_records_userId_createdAt` ON `notification_records` (`userId`, `createdAt`)")
            }
        }
    }
}
