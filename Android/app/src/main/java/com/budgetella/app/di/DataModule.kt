package com.budgetella.app.di

import android.content.Context
import androidx.room.Room
import com.budgetella.app.data.local.BudgetellaDatabase
import com.budgetella.app.data.local.dao.AppSettingsDao
import com.budgetella.app.data.local.dao.BudgetDao
import com.budgetella.app.data.local.dao.CategoryDao
import com.budgetella.app.data.local.dao.GoalDao
import com.budgetella.app.data.local.dao.NotificationRecordDao
import com.budgetella.app.data.local.dao.TransactionDao
import com.budgetella.app.data.local.dao.UserDao
import com.budgetella.app.data.repository.AppSettingsRepository
import com.budgetella.app.data.repository.BudgetRepository
import com.budgetella.app.data.repository.CategoryRepository
import com.budgetella.app.data.repository.GoalRepository
import com.budgetella.app.data.repository.NotificationRepository
import com.budgetella.app.data.repository.RoomAppSettingsRepository
import com.budgetella.app.data.repository.RoomBudgetRepository
import com.budgetella.app.data.repository.RoomCategoryRepository
import com.budgetella.app.data.repository.RoomGoalRepository
import com.budgetella.app.data.repository.RoomNotificationRepository
import com.budgetella.app.data.repository.RoomTransactionRepository
import com.budgetella.app.data.repository.RoomUserRepository
import com.budgetella.app.data.repository.TransactionRepository
import com.budgetella.app.data.repository.UserRepository
import dagger.Binds
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Provides the Room database, the six DAOs, and binds repository interfaces to
 * their Room-backed implementations. Single source of truth for the data layer
 * — every screen ViewModel pulls dependencies from here via @Inject.
 */
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): BudgetellaDatabase =
        Room.databaseBuilder(
            context,
            BudgetellaDatabase::class.java,
            BudgetellaDatabase.DATABASE_NAME
        )
            // Explicit migrations only — never fallback to destructive.
            .addMigrations(BudgetellaDatabase.MIGRATION_1_2)
            .build()

    @Provides fun provideTransactionDao(db: BudgetellaDatabase): TransactionDao = db.transactionDao()
    @Provides fun provideCategoryDao(db: BudgetellaDatabase): CategoryDao       = db.categoryDao()
    @Provides fun provideUserDao(db: BudgetellaDatabase): UserDao               = db.userDao()
    @Provides fun provideAppSettingsDao(db: BudgetellaDatabase): AppSettingsDao = db.appSettingsDao()
    @Provides fun provideBudgetDao(db: BudgetellaDatabase): BudgetDao           = db.budgetDao()
    @Provides fun provideGoalDao(db: BudgetellaDatabase): GoalDao               = db.goalDao()
    @Provides fun provideNotificationRecordDao(db: BudgetellaDatabase): NotificationRecordDao = db.notificationRecordDao()
}

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds @Singleton
    abstract fun bindTransactionRepository(impl: RoomTransactionRepository): TransactionRepository

    @Binds @Singleton
    abstract fun bindCategoryRepository(impl: RoomCategoryRepository): CategoryRepository

    @Binds @Singleton
    abstract fun bindUserRepository(impl: RoomUserRepository): UserRepository

    @Binds @Singleton
    abstract fun bindAppSettingsRepository(impl: RoomAppSettingsRepository): AppSettingsRepository

    @Binds @Singleton
    abstract fun bindBudgetRepository(impl: RoomBudgetRepository): BudgetRepository

    @Binds @Singleton
    abstract fun bindGoalRepository(impl: RoomGoalRepository): GoalRepository

    @Binds @Singleton
    abstract fun bindNotificationRepository(impl: RoomNotificationRepository): NotificationRepository
}
