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
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.firebase.FirebaseNetworkException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuthInvalidCredentialsException
import com.google.firebase.auth.FirebaseAuthUserCollisionException
import com.google.firebase.auth.FirebaseAuthWeakPasswordException
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.userProfileChangeRequest
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
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
) : AuthRepository {

    override val state: Flow<AuthState> = callbackFlow {
        val listener = FirebaseAuth.AuthStateListener { fb ->
            trySend(fb.currentUser.toAuthState())
        }
        // Emit current value immediately so collectors don't sit on Unknown.
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

        val request = GetCredentialRequest.Builder()
            .addCredentialOption(
                GetGoogleIdOption.Builder()
                    .setServerClientId(webClientId)
                    .setFilterByAuthorizedAccounts(false)
                    .setAutoSelectEnabled(true)
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
        auth.signOut()
        userRepository.signOutLocal()
        // Note: deliberately NOT wiping transactions/categories so a re-login
        // sees the existing rows merged with Firestore. iOS does the same.
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private suspend fun afterSignIn(user: FirebaseUser) {
        val now = System.currentTimeMillis()
        val existing = userRepository.getUser(user.uid)
        val entity = (existing ?: UserEntity(
            uid = user.uid,
            email = user.email.orEmpty(),
            createdAt = now,
            updatedAt = now,
        )).copy(
            email = user.email.orEmpty(),
            displayName = user.displayName,
            photoURL = user.photoUrl?.toString(),
            updatedAt = now,
            lastSyncedAt = now,
        )
        userRepository.upsert(entity)
        dataInitializer.seedSuspending(user.uid)
        // Pull existing Firestore data so a user who's been on iOS sees their
        // history immediately on Android. Errors swallowed — the user can
        // still operate offline; the next write will catch sync back up.
        runCatching { firestoreService.fetchAndSync(user.uid) }
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
