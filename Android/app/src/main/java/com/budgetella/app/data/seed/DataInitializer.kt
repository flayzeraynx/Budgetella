package com.budgetella.app.data.seed

import com.budgetella.app.data.repository.AppSettingsRepository
import com.budgetella.app.data.repository.CategoryRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

/**
 * First-launch seeding. Mirrors iOS BudgetellaApp.seed*IfNeeded():
 *
 *   - 15 default categories per user
 *   - One AppSettings row per user
 *
 * Both methods are idempotent — they bail out fast if the seed has already
 * happened, so calling on every app launch is safe.
 *
 * The placeholder userId "local" is what the app uses before sign-in (matches
 * iOS `currentUserId.isEmpty ? "local" : currentUserId`). Once the user signs
 * in, AuthService will call [seedFor] again with their real Firebase UID.
 */
@Singleton
class DataInitializer @Inject constructor(
    private val categoryRepository: CategoryRepository,
    private val appSettingsRepository: AppSettingsRepository,
) {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    /** Fire-and-forget. Safe to call from Application.onCreate(). */
    fun seedFor(userId: String) {
        scope.launch {
            categoryRepository.seedDefaultsIfNeeded(userId)
            appSettingsRepository.ensureExists(userId)
        }
    }

    /** Suspending variant for callers that already have a coroutine context (auth flow). */
    suspend fun seedSuspending(userId: String) {
        categoryRepository.seedDefaultsIfNeeded(userId)
        appSettingsRepository.ensureExists(userId)
    }

    companion object {
        const val LOCAL_USER_ID: String = "local"
    }
}
