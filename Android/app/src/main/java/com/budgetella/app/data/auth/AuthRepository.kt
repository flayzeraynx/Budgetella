package com.budgetella.app.data.auth

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow

/**
 * Auth boundary — every UI screen and ViewModel talks to this interface
 * instead of FirebaseAuth directly. Tests can swap in a fake; the production
 * impl is [FirebaseAuthRepository].
 *
 * API mirrors the iOS AuthService surface but drops methods deferred to
 * later milestones (Apple sign-in, OTP, password update, delete-account).
 */
interface AuthRepository {

    /** Live auth state, broadcast on every FirebaseAuth state change. */
    val state: Flow<AuthState>

    /**
     * True while the post-sign-in Firestore fetch is running. FirebaseAuth
     * fires SignedIn the instant credentials are accepted — long before the
     * user's existing transactions / categories have been pulled down. The
     * AppRoot watches this so it can keep a sync screen up instead of
     * dropping into the Main shell with empty lists for the 3–6 seconds
     * it takes the fetch to land.
     */
    val isInitialSyncInProgress: StateFlow<Boolean>

    /** Synchronous snapshot — only useful for the splash screen's first read. */
    fun currentState(): AuthState

    suspend fun signUpEmailPassword(
        email: String,
        password: String,
        displayName: String,
    ): AuthResult

    suspend fun signInEmailPassword(
        email: String,
        password: String,
    ): AuthResult

    suspend fun sendPasswordReset(email: String): AuthResult

    /**
     * Initiates Google Sign-In via the Credential Manager API. Caller must
     * provide an `androidx.activity.ComponentActivity` so the credential
     * picker can attach to its window. Returns Success once the Firebase
     * credential has been exchanged.
     */
    suspend fun signInWithGoogle(activity: androidx.activity.ComponentActivity): AuthResult

    suspend fun signOut()

    /**
     * Re-authenticate the currently signed-in user with their password. Used
     * before destructive operations (delete account, change password) when
     * Firebase reports requiresRecentLogin. Returns Success on a valid
     * password, [AuthError.InvalidCredentials] on a wrong one, and
     * [AuthError.NotConfigured] if the current account isn't email/password.
     */
    suspend fun reauthenticateWithPassword(password: String): AuthResult

    /**
     * Permanent delete: wipes the Firestore `users/{uid}` document tree and
     * removes the Firebase Auth account itself. If Firebase requires a recent
     * login the call returns [AuthError.RecentLoginRequired] without doing any
     * deletion, so the UI can prompt the user to re-auth first.
     */
    suspend fun deleteAccount(): AuthResult
}
