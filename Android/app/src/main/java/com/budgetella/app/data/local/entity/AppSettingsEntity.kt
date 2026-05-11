package com.budgetella.app.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.budgetella.app.data.model.AppCurrency
import com.budgetella.app.data.model.AppLanguage
import com.budgetella.app.data.model.AppTheme

/**
 * Per-user preferences row — port of iOS AppSettings.swift.
 *
 * One row per userId. While the user is logged out we use a placeholder
 * userId of "local" so the app can still persist preferences before sign-in
 * (matches iOS's `currentUserId.isEmpty ? "local" : currentUserId` pattern).
 *
 * Sensitive data (auth tokens, biometric keys) does NOT live here — that's
 * EncryptedSharedPreferences / Keystore territory.
 */
@Entity(tableName = "app_settings")
data class AppSettingsEntity(
    @PrimaryKey val userId: String,

    @ColumnInfo(name = "currency") val currencyRaw: String = AppCurrency.Try.raw,
    @ColumnInfo(name = "language") val languageRaw: String = AppLanguage.English.raw,
    @ColumnInfo(name = "theme")    val themeRaw: String    = AppTheme.Dark.raw,

    val hideAmounts: Boolean = false,
    val biometricLockEnabled: Boolean = false,
    val notificationsEnabled: Boolean = true,

    val updatedAt: Long,
) {
    val currency: AppCurrency get() = AppCurrency.fromRaw(currencyRaw)
    val language: AppLanguage get() = AppLanguage.fromRaw(languageRaw)
    val theme:    AppTheme    get() = AppTheme.fromRaw(themeRaw)
}
