package com.budgetella.app.data.repository

import com.budgetella.app.data.local.dao.AppSettingsDao
import com.budgetella.app.data.local.entity.AppSettingsEntity
import com.budgetella.app.data.model.AppCurrency
import com.budgetella.app.data.model.AppLanguage
import com.budgetella.app.data.model.AppTheme
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

interface AppSettingsRepository {
    fun observe(userId: String): Flow<AppSettingsEntity>
    suspend fun current(userId: String): AppSettingsEntity

    suspend fun setCurrency(userId: String, currency: AppCurrency)
    suspend fun setLanguage(userId: String, language: AppLanguage)
    suspend fun setTheme(userId: String, theme: AppTheme)
    suspend fun setHideAmounts(userId: String, hide: Boolean)
    suspend fun setBiometricLock(userId: String, enabled: Boolean)
    suspend fun setNotifications(userId: String, enabled: Boolean)

    /** Idempotent — creates a default row for a new user. */
    suspend fun ensureExists(userId: String)
}

@Singleton
class RoomAppSettingsRepository @Inject constructor(
    private val dao: AppSettingsDao,
) : AppSettingsRepository {

    override fun observe(userId: String): Flow<AppSettingsEntity> =
        dao.observeForUser(userId).map { it ?: defaultRow(userId) }

    override suspend fun current(userId: String): AppSettingsEntity =
        dao.findForUser(userId) ?: defaultRow(userId).also { dao.upsert(it) }

    override suspend fun setCurrency(userId: String, currency: AppCurrency) =
        update(userId) { it.copy(currencyRaw = currency.raw) }

    override suspend fun setLanguage(userId: String, language: AppLanguage) =
        update(userId) { it.copy(languageRaw = language.raw) }

    override suspend fun setTheme(userId: String, theme: AppTheme) =
        update(userId) { it.copy(themeRaw = theme.raw) }

    override suspend fun setHideAmounts(userId: String, hide: Boolean) =
        update(userId) { it.copy(hideAmounts = hide) }

    override suspend fun setBiometricLock(userId: String, enabled: Boolean) =
        update(userId) { it.copy(biometricLockEnabled = enabled) }

    override suspend fun setNotifications(userId: String, enabled: Boolean) =
        update(userId) { it.copy(notificationsEnabled = enabled) }

    override suspend fun ensureExists(userId: String) {
        if (dao.findForUser(userId) == null) dao.upsert(defaultRow(userId))
    }

    private suspend fun update(userId: String, block: (AppSettingsEntity) -> AppSettingsEntity) {
        val row = current(userId)
        dao.upsert(block(row).copy(updatedAt = System.currentTimeMillis()))
    }

    private fun defaultRow(userId: String): AppSettingsEntity =
        AppSettingsEntity(
            userId = userId,
            updatedAt = System.currentTimeMillis(),
        )
}
