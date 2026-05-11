package com.budgetella.app.data.auth

import android.content.Context
import androidx.activity.ComponentActivity
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import com.budgetella.app.data.local.entity.UserEntity
import com.budgetella.app.data.remote.FirestoreService
import com.budgetella.app.data.repository.UserRepository
import com.budgetella.app.data.seed.DataInitializer
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.firebase.FirebaseNetworkException
import com.google.firebase.auth.EmailAuthProvider
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuthInvalidCredentialsException
import com.google.firebase.auth.FirebaseAuthRecentLoginRequiredException
import com.google.firebase.auth.FirebaseAuthUserCollisionException
import com.google.firebase.auth.FirebaseAuthWeakPasswordException
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.userProfileChangeRequest
import com.google.firebase.firestore.FirebaseFirestore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Firebase-backed [AuthRepository]. Handles email/password + Google.
 *
 * Side effects on successful sign-in/sign-up:
 *   1. Upserts a UserEntity row in Room so the rest of the app can read
 *      profile fields without an extra Firestore round-trip.
 *   2. Calls DataInitializer.seedSuspending(uid) so the new account gets
 *      the 15 default categories + AppSettings row — matches what the iOS
 *      FirestoreService.fetchAndSync does on the very first sign-in.
 *
 * Google Sign-In uses the modern Credential Manager API; the legacy
 * GoogleSignInClient is deprecated and Play Services no longer ships the
 * full UI for it.
 */
@Singleton
class FirebaseAuthRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val auth: FirebaseAuth,
    private val userRepository: UserRepository,
    private val dataInitializer: DataInitializer,
    private val firestoreService: FirestoreService,
    private val firestore: FirebaseFirestore,
) : AuthRepository {

    private val _isInitialSyncInProgress = MutableStateFlow(false)
    override val isInitialSyncInProgress: StateFlow<Boolean> = _isInitialSyncInProgress.asStateFlow()

    override val state: Flow<AuthState> = callbackFlow {
        val listener = FirebaseAuth.AuthStateListener { fb ->
            val user = fb.currentUser
            // Keep Firestore snapshot listeners synchronized with the auth
            // session: attach on sign-in, detach on sign-out. This is how a
            // returning user (warm app launch with existing session) gets
            // live updates from iOS — afterSignIn only runs on the initial
            // sign-in flow, not on cold launches with cached credentials.
            if (user != null) firestoreService.startObserving(user.uid)
            else firestoreService.stopObserving()
            trySend(user.toAuthState())
        }
        // Emit current value immediately so collectors don't sit on Unknown.
        auth.currentUser?.let { firestoreService.startObserving(it.uid) }
        trySend(auth.currentUser.toAuthState())
        auth.addAuthStateListener(listener)
        awaitClose { auth.removeAuthStateListener(listener) }
    }.flowOn(Dispatchers.IO)

    override fun currentState(): AuthState = auth.currentUser.toAuthState()

    // ── Email/password ─────────────────────────────────────────────────────

    override suspend fun signUpEmailPassword(
        email: String,
        password: String,
        displayName: String,
    ): AuthResult = runAuth {
        val result = auth.createUserWithEmailAndPassword(email.trim(), password).await()
        val user = result.user ?: error("Firebase returned a null user on signUp")
        // Set displayName immediately so the UserEntity row carries it.
        if (displayName.isNotBlank()) {
            user.updateProfile(userProfileChangeRequest { this.displayName = displayName.trim() }).await()
            user.reload().await()
        }
        afterSignIn(user)
        // Fire-and-forget the verification email — iOS does this too. Errors are
        // tolerated; the user can re-trigger from the verification screen later.
        runCatching { user.sendEmailVerification().await() }
    }

    override suspend fun signInEmailPassword(
        email: String,
        password: String,
    ): AuthResult = runAuth {
        val result = auth.signInWithEmailAndPassword(email.trim(), password).await()
        val user = result.user ?: error("Firebase returned a null user on signIn")
        afterSignIn(user)
    }

    override suspend fun sendPasswordReset(email: String): AuthResult = runAuth {
        auth.sendPasswordResetEmail(email.trim()).await()
    }

    // ── Google ─────────────────────────────────────────────────────────────

    override suspend fun signInWithGoogle(activity: ComponentActivity): AuthResult {
        val webClientId = runCatching {
            context.getString(R_string_default_web_client_id)
        }.getOrNull()
        if (webClientId.isNullOrBlank()) {
            // google-services.json hasn't been dropped into app/ yet (the
            // plugin generates default_web_client_id from it). Surface a
            // distinct error instead of an opaque crash.
            return AuthResult.Failure(AuthError.NotConfigured)
        }

        // GetSignInWithGoogleOption is the explicit "Sign in with Google" button
        // flow: it always opens the modal account picker and exposes the
        // "Use another account" / "Add account" entries — exactly what users
        // expect when tapping a sign-in CTA. GetGoogleIdOption is the silent
        // one-tap variant we'd use for re-auth, but it can pre-select the
        // last account and hide the picker, which is what was confusing
        // people who wanted to sign in with a different Google account.
        val request = GetCredentialRequest.Builder()
            .addCredentialOption(
                GetSignInWithGoogleOption.Builder(webClientId)
                    .build()
            )
            .build()

        val credentialManager = CredentialManager.create(context)
        return runAuth {
            val response = try {
                credentialManager.getCredential(activity, request)
            } catch (cancel: GetCredentialCancellationException) {
                throw UserCancelledException
            } catch (e: GetCredentialException) {
                throw e
            }
            val credential = response.credential
            val googleIdToken = when (credential) {
                is CustomCredential -> {
                    if (credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                        GoogleIdTokenCredential.createFrom(credential.data).idToken
                    } else error("Unexpected Google credential type: ${credential.type}")
                }
                else -> error("Unexpected credential class: ${credential::class.java.simpleName}")
            }
            val firebaseCredential = GoogleAuthProvider.getCredential(googleIdToken, null)
            val firebaseUser = auth.signInWithCredential(firebaseCredential).await().user
                ?: error("Firebase returned a null user on Google sign-in")
            afterSignIn(firebaseUser)
        }
    }

    // ── Sign out ───────────────────────────────────────────────────────────

    override suspend fun signOut() {
        firestoreService.stopObserving()
        auth.signOut()
        userRepository.signOutLocal()
        // Note: deliberately NOT wiping transactions/categories so a re-login
        // sees the existing rows merged with Firestore. iOS does the same.
    }

    // ── Re-auth + delete ───────────────────────────────────────────────────

    override suspend fun reauthenticateWithPassword(password: String): AuthResult {
        val user = auth.currentUser ?: return AuthResult.Failure(AuthError.InvalidCredentials)
        val email = user.email
        val isEmailProvider = user.providerData.any { it.providerId == "password" }
        if (email.isNullOrBlank() || !isEmailProvider) {
            return AuthResult.Failure(AuthError.NotConfigured)
        }
        return try {
            val credential = EmailAuthProvider.getCredential(email, password)
            user.reauthenticate(credential).await()
            AuthResult.Success
        } catch (e: FirebaseAuthInvalidCredentialsException) {
            AuthResult.Failure(AuthError.InvalidCredentials)
        } catch (e: FirebaseNetworkException) {
            AuthResult.Failure(AuthError.NetworkUnavailable)
        } catch (t: Throwable) {
            AuthResult.Failure(AuthError.Unknown)
        }
    }

    override suspend fun deleteAccount(): AuthResult {
        val user = auth.currentUser ?: return AuthResult.Failure(AuthError.InvalidCredentials)
        val uid = user.uid
        return try {
            // Best-effort Firestore wipe — mirrors iOS AuthService.deleteAccount.
            // If this fails, abort so we never delete the auth account while the
            // user's data is still in Firestore (orphaned data is worse than
            // leaving the auth account around).
            runCatching {
                firestore.collection("users").document(uid).delete().await()
            }
            // Auth account deletion. Will throw if the most recent sign-in is
            // older than ~5 minutes; the UI surfaces that via RecentLoginRequired.
            user.delete().await()
            userRepository.signOutLocal()
            AuthResult.Success
        } catch (e: FirebaseAuthRecentLoginRequiredException) {
            AuthResult.Failure(AuthError.RecentLoginRequired)
        } catch (e: FirebaseNetworkException) {
            AuthResult.Failure(AuthError.NetworkUnavailable)
        } catch (t: Throwable) {
            AuthResult.Failure(AuthError.Unknown)
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private suspend fun afterSignIn(user: FirebaseUser) {
        val now = System.currentTimeMillis()
        val existing = userRepository.getUser(user.uid)
        // Force-reload so federated providers (Google) have their photoURL +
        // displayName populated before we cache them. Email/password accounts
        // get their displayName from createUserWithEmailAndPassword's profile
        // update; this call is a cheap no-op for them.
        runCatching { user.reload().await() }
        val freshUser = auth.currentUser ?: user

        // For optional fields we prefer the freshly-loaded Firebase value, but
        // fall back to whatever we already had cached locally instead of
        // overwriting with null — this is the difference between a brand-new
        // account (no cached row, Firebase returns null → keep null) and a
        // returning user whose existing row already carries the name and
        // shouldn't be wiped just because Firebase hasn't re-emitted it yet.
        val resolvedDisplayName = freshUser.displayName?.takeIf { it.isNotBlank() }
            ?: existing?.displayName
        val resolvedPhotoUrl = freshUser.photoUrl?.toString()?.takeIf { it.isNotBlank() }
            ?: existing?.photoURL
        val resolvedEmail = freshUser.email?.takeIf { it.isNotBlank() }
            ?: existing?.email
            ?: ""

        val entity = (existing ?: UserEntity(
            uid = freshUser.uid,
            email = resolvedEmail,
            createdAt = now,
            updatedAt = now,
        )).copy(
            email = resolvedEmail,
            displayName = resolvedDisplayName,
            photoURL = resolvedPhotoUrl,
            updatedAt = now,
            lastSyncedAt = now,
        )
        userRepository.upsert(entity)
        dataInitializer.seedSuspending(user.uid)
        // Flip the sync flag *before* fetchAndSync runs so AppRoot can hold
        // a "syncing your data" screen during the 3–6 s Firestore round-trip
        // instead of dropping into Main with empty Room tables. Cleared in
        // `finally` so a network failure doesn't leave the app stuck.
        _isInitialSyncInProgress.value = true
        try {
            // Pull existing Firestore data so a user who's been on iOS sees
            // their history immediately on Android. Errors swallowed — the
            // user can still operate offline; the next write will catch sync
            // back up.
            runCatching { firestoreService.fetchAndSync(user.uid) }
        } finally {
            _isInitialSyncInProgress.value = false
        }
        // After the initial pull, attach snapshot listeners for live two-way
        // sync — edits from iOS land in Room within a few hundred ms.
        firestoreService.startObserving(user.uid)
    }

    private suspend inline fun runAuth(block: () -> Unit): AuthResult =
        try {
            block()
            AuthResult.Success
        } catch (cancel: UserCancelledException) {
            AuthResult.Failure(AuthError.UserCancelled)
        } catch (e: FirebaseAuthWeakPasswordException) {
            AuthResult.Failure(AuthError.WeakPassword)
        } catch (e: FirebaseAuthUserCollisionException) {
            AuthResult.Failure(AuthError.EmailAlreadyInUse)
        } catch (e: FirebaseAuthInvalidCredentialsException) {
            AuthResult.Failure(AuthError.InvalidCredentials)
        } catch (e: FirebaseNetworkException) {
            AuthResult.Failure(AuthError.NetworkUnavailable)
        } catch (t: Throwable) {
            AuthResult.Failure(AuthError.Unknown)
        }

    private object UserCancelledException : RuntimeException()

    // R.string.default_web_client_id is auto-generated by the google-services
    // plugin when google-services.json is present. Looked up by id to avoid a
    // compile-time dependency before the file is dropped in.
    private val R_string_default_web_client_id: Int
        get() = context.resources.getIdentifier(
            "default_web_client_id", "string", context.packageName
        )

    private fun FirebaseUser?.toAuthState(): AuthState {
        if (this == null) return AuthState.SignedOut
        val isEmailProvider = providerData.any { it.providerId == "password" }
        return AuthState.SignedIn(
            uid = uid,
            email = email.orEmpty(),
            displayName = displayName,
            photoUrl = photoUrl?.toString(),
            emailVerified = isEmailVerified,
            isEmailProvider = isEmailProvider,
        )
    }
}
