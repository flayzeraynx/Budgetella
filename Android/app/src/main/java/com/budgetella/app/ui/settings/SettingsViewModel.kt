package com.budgetella.app.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.budgetella.app.data.auth.AuthRepository
import com.budgetella.app.data.local.entity.AppSettingsEntity
import com.budgetella.app.data.local.entity.UserEntity
import com.budgetella.app.data.model.AppCurrency
import com.budgetella.app.data.model.AppLanguage
import com.budgetella.app.data.model.AppTheme
import com.budgetella.app.data.prefs.UserPrefs
import com.budgetella.app.data.repository.AppSettingsRepository
import com.budgetella.app.data.repository.UserRepository
import com.google.firebase.firestore.FirebaseFirestore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import javax.inject.Inject

/**
 * View-state for the Settings sheet. Mirrors iOS SettingsViewModel — composes
 * the per-user [AppSettingsEntity] with the cached [UserEntity] so the profile
 * card can show display name + email + photo without an extra round-trip.
 */
data class SettingsState(
    val appSettings: AppSettingsEntity? = null,
    val user: UserEntity? = null,
) {
    val displayName: String? get() = user?.displayName
    val email: String? get() = user?.email
    val photoUrl: String? get() = user?.photoURL
    val theme: AppTheme get() = appSettings?.theme ?: AppTheme.Dark
    val language: AppLanguage get() = appSettings?.language ?: AppLanguage.English
    val currency: AppCurrency get() = appSettings?.currency ?: AppCurrency.Try
    val hideAmounts: Boolean get() = appSettings?.hideAmounts == true
    val biometricLockEnabled: Boolean get() = appSettings?.biometricLockEnabled == true
    val notificationsEnabled: Boolean get() = appSettings?.notificationsEnabled != false
    val isPremium: Boolean get() = user?.hasActivePremium() == true
}

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val userPrefs: UserPrefs,
    private val appSettingsRepository: AppSettingsRepository,
    private val userRepository: UserRepository,
    private val authRepository: AuthRepository,
    private val firestore: FirebaseFirestore,
) : ViewModel() {

    @OptIn(ExperimentalCoroutinesApi::class)
    val state: StateFlow<SettingsState> = userPrefs.currentUserId
        .flatMapLatest { uid ->
            combine(
                appSettingsRepository.observe(uid),
                userRepository.observeUser(uid),
            ) { settings, user -> SettingsState(appSettings = settings, user = user) }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), SettingsState())

    // ── Mutations ──────────────────────────────────────────────────────────

    fun setTheme(theme: AppTheme) = withUid { uid -> appSettingsRepository.setTheme(uid, theme) }

    fun setLanguage(language: AppLanguage) = withUid { uid -> appSettingsRepository.setLanguage(uid, language) }

    fun setCurrency(currency: AppCurrency) = withUid { uid -> appSettingsRepository.setCurrency(uid, currency) }

    fun setHideAmounts(hide: Boolean) = withUid { uid -> appSettingsRepository.setHideAmounts(uid, hide) }

    fun setBiometric(enabled: Boolean) = withUid { uid -> appSettingsRepository.setBiometricLock(uid, enabled) }

    fun setNotifications(enabled: Boolean) = withUid { uid -> appSettingsRepository.setNotifications(uid, enabled) }

    // ── Account ────────────────────────────────────────────────────────────

    fun signOut() {
        viewModelScope.launch {
            runCatching { authRepository.signOut() }
        }
    }

    /**
     * Best-effort account deletion. Wipes the `users/{uid}` Firestore document
     * and signs out. Firebase Auth deletion of the user itself requires a
     * recent re-auth — that flow is deferred to a follow-up.
     */
    fun deleteAccount() {
        viewModelScope.launch {
            val uid = userPrefs.currentUserId.first()
            runCatching {
                firestore.collection("users").document(uid).delete().await()
            }
            runCatching { authRepository.signOut() }
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private inline fun withUid(crossinline block: suspend (String) -> Unit) {
        viewModelScope.launch {
            val uid = userPrefs.currentUserId.first()
            block(uid)
        }
    }
}
