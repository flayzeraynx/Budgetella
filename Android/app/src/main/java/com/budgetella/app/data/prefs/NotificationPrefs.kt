package com.budgetella.app.data.prefs

import android.content.Context
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Fine-grained notification preferences — port of iOS @AppStorage flags in
 * NotificationSettingsView. Stored separately from the per-user AppSettings
 * row because:
 *  - These are device-level preferences (you can have notifications on for
 *    one Android device and off for another, even on the same account)
 *  - Plays nicer than running a Room migration just to add three booleans
 *  - Mirrors iOS, which uses UserDefaults for the same surface
 */
private val Context.notifPrefs by preferencesDataStore(name = "notification_prefs")

@Singleton
class NotificationPrefs @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private object Keys {
        val AllEnabled: Preferences.Key<Boolean> = booleanPreferencesKey("notifAllEnabled")
        val WeeklyDigest: Preferences.Key<Boolean> = booleanPreferencesKey("notifWeeklyDigest")
        val AnomalyAlerts: Preferences.Key<Boolean> = booleanPreferencesKey("notifAnomalyAlerts")
        val SavingsSuggestions: Preferences.Key<Boolean> = booleanPreferencesKey("notifSavingsSuggestions")
    }

    data class State(
        val allEnabled: Boolean = true,
        val weeklyDigest: Boolean = true,
        val anomalyAlerts: Boolean = true,
        val savingsSuggestions: Boolean = true,
    )

    val state: Flow<State> = context.notifPrefs.data.map { prefs ->
        State(
            allEnabled = prefs[Keys.AllEnabled] ?: true,
            weeklyDigest = prefs[Keys.WeeklyDigest] ?: true,
            anomalyAlerts = prefs[Keys.AnomalyAlerts] ?: true,
            savingsSuggestions = prefs[Keys.SavingsSuggestions] ?: true,
        )
    }

    suspend fun setAllEnabled(value: Boolean) =
        context.notifPrefs.edit { it[Keys.AllEnabled] = value }.let { Unit }

    suspend fun setWeeklyDigest(value: Boolean) =
        context.notifPrefs.edit { it[Keys.WeeklyDigest] = value }.let { Unit }

    suspend fun setAnomalyAlerts(value: Boolean) =
        context.notifPrefs.edit { it[Keys.AnomalyAlerts] = value }.let { Unit }

    suspend fun setSavingsSuggestions(value: Boolean) =
        context.notifPrefs.edit { it[Keys.SavingsSuggestions] = value }.let { Unit }
}
