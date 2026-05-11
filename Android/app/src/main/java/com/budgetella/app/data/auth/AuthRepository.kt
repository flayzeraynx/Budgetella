package com.budgetella.app.data.auth

import kotlinx.coroutines.flow.Flow

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
}
