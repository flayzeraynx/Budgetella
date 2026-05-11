package com.budgetella.app.data.auth

/**
 * Snapshot of the current Firebase auth session. Drives [AppState] routing —
 * Splash watches the initial value, Auth pages collect updates, the main shell
 * uses [signedInUserId] when querying Room.
 */
sealed interface AuthState {

    /** Auth status not yet known — keep showing splash. */
    data object Unknown : AuthState

    /** No user signed in. */
    data object SignedOut : AuthState

    /**
     * Signed in. `emailVerified` matters only for email/password users; SSO
     * providers (Google, Apple) report `true` immediately.
     */
    data class SignedIn(
        val uid: String,
        val email: String,
        val displayName: String?,
        val photoUrl: String?,
        val emailVerified: Boolean,
        val isEmailProvider: Boolean,
    ) : AuthState
}

/**
 * Typed result for one-shot auth calls. Avoids forcing every call-site to
 * catch FirebaseAuthExceptions and map them to localised copy by hand.
 */
sealed interface AuthResult {
    data object Success : AuthResult
    data class Failure(val error: AuthError) : AuthResult
}

enum class AuthError {
    InvalidCredentials,
    EmailAlreadyInUse,
    WeakPassword,
    InvalidEmail,
    NetworkUnavailable,
    UserCancelled,
    NotConfigured,
    Unknown,
}
