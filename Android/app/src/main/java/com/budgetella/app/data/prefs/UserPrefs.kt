package com.budgetella.app.data.prefs

import android.content.Context
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.budgetella.app.data.seed.DataInitializer
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Lightweight, structured wrapper over a DataStore Preferences file —
 * replaces the scattered SharedPreferences calls from M0 and gives the rest
 * of the app a typed surface for the iOS @AppStorage equivalents.
 *
 * Two keys for now:
 *   - hasCompletedOnboarding: drives the AppState splash → onboarding → auth fork
 *   - currentUserId: cached UID so the data layer can read "the active user's
 *     rows" without round-tripping FirebaseAuth on every screen
 */
private val Context.userPrefsDataStore by preferencesDataStore(name = "user_prefs")

@Singleton
class UserPrefs @Inject constructor(
    @ApplicationContext private val context: Context,
) {

    private object Keys {
        val HasCompletedOnboarding: Preferences.Key<Boolean> = booleanPreferencesKey("hasCompletedOnboarding")
        val CurrentUserId: Preferences.Key<String> = stringPreferencesKey("currentUserId")
    }

    val hasCompletedOnboarding: Flow<Boolean> =
        context.userPrefsDataStore.data.map { it[Keys.HasCompletedOnboarding] ?: false }

    val currentUserId: Flow<String> =
        context.userPrefsDataStore.data.map { it[Keys.CurrentUserId] ?: DataInitializer.LOCAL_USER_ID }

    suspend fun markOnboardingComplete() {
        context.userPrefsDataStore.edit { it[Keys.HasCompletedOnboarding] = true }
    }

    suspend fun setCurrentUserId(uid: String) {
        context.userPrefsDataStore.edit { it[Keys.CurrentUserId] = uid }
    }

    suspend fun clearCurrentUserId() {
        context.userPrefsDataStore.edit { it.remove(Keys.CurrentUserId) }
    }
}
