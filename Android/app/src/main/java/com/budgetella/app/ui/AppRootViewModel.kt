package com.budgetella.app.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.budgetella.app.data.auth.AuthRepository
import com.budgetella.app.data.auth.AuthState
import com.budgetella.app.data.model.AppCurrency
import com.budgetella.app.data.model.AppTheme
import com.budgetella.app.data.prefs.UserPrefs
import com.budgetella.app.data.repository.AppSettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

/** Coarse-grained app-shell state — drives [AppRoot]. */
enum class AppRootState { Splash, Onboarding, Auth, SyncingInitial, BiometricLock, Main }

@HiltViewModel
class AppRootViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val userPrefs: UserPrefs,
    private val appSettingsRepository: AppSettingsRepository,
) : ViewModel() {

    /**
     * Transient — true once the user has cleared the biometric prompt for the
     * current process. Cold launches reset this back to false so the lock
     * shows again every time the app comes back from a killed state. We also
     * reset it on sign-out so a fresh login through a different account on
     * the same device starts behind the prompt again.
     */
    private val biometricCleared = MutableStateFlow(false)

    @OptIn(ExperimentalCoroutinesApi::class)
    val state: StateFlow<AppRootState> = combine(
        authRepository.state,
        userPrefs.hasCompletedOnboarding,
    ) { auth, onboarded -> Triple(auth, onboarded, Unit) }
        .flatMapLatest { (auth, onboarded, _) ->
            when {
                auth is AuthState.Unknown -> flowOf(AppRootState.Splash)
                !onboarded -> flowOf(AppRootState.Onboarding)
                auth is AuthState.SignedOut -> flowOf(AppRootState.Auth)
                auth is AuthState.SignedIn -> {
                    // Mirror the active uid so the rest of the data layer can
                    // read it without an extra FirebaseAuth call.
                    viewModelScope.launch { userPrefs.setCurrentUserId(auth.uid) }
                    combine(
                        appSettingsRepository.observe(auth.uid),
                        biometricCleared,
                        authRepository.isInitialSyncInProgress,
                    ) { settings, cleared, syncing ->
                        when {
                            syncing -> AppRootState.SyncingInitial
                            settings.biometricLockEnabled && !cleared -> AppRootState.BiometricLock
                            else -> AppRootState.Main
                        }
                    }
                }
                else -> flowOf(AppRootState.Splash)
            }
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.Eagerly,
            initialValue = AppRootState.Splash,
        )

    /**
     * Active user's hide-amounts preference. Provided to the composition via
     * [LocalHideAmounts] so every Text that renders currency can mask itself
     * without prop-drilling through the screen tree.
     */
    @OptIn(ExperimentalCoroutinesApi::class)
    val hideAmounts: StateFlow<Boolean> = userPrefs.currentUserId
        .flatMapLatest { uid -> appSettingsRepository.observe(uid) }
        .map { it.hideAmounts }
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)

    /**
     * Active user's theme preference (Dark/Light/System). Drives the top-level
     * Material color scheme. Defaults to Dark — mirrors the iOS shipping
     * behaviour where the brand experience is dark-first.
     */
    @OptIn(ExperimentalCoroutinesApi::class)
    val theme: StateFlow<AppTheme> = userPrefs.currentUserId
        .flatMapLatest { uid -> appSettingsRepository.observe(uid) }
        .map { it.theme }
        .stateIn(viewModelScope, SharingStarted.Eagerly, AppTheme.Dark)

    /**
     * Active display currency — the symbol every money formatter falls back
     * to when a call site doesn't pin its own (e.g. dashboard hero, year
     * totals). Transactions keep their per-row `currency` field as the
     * source of truth for the underlying value.
     */
    @OptIn(ExperimentalCoroutinesApi::class)
    val currency: StateFlow<AppCurrency> = userPrefs.currentUserId
        .flatMapLatest { uid -> appSettingsRepository.observe(uid) }
        .map { it.currency }
        .stateIn(viewModelScope, SharingStarted.Eagerly, AppCurrency.Try)

    fun onOnboardingFinished() {
        viewModelScope.launch { userPrefs.markOnboardingComplete() }
    }

    /** Called by [BiometricLockScreen] after a successful authentication. */
    fun onBiometricUnlocked() {
        biometricCleared.value = true
    }

    /** Sign-out triggered from the biometric screen's secondary action. */
    fun onBiometricSignOut() {
        viewModelScope.launch {
            biometricCleared.value = false
            authRepository.signOut()
        }
    }
}
