package com.budgetella.app.ui.auth

import androidx.activity.ComponentActivity
import androidx.annotation.StringRes
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.budgetella.app.R
import com.budgetella.app.data.auth.AuthError
import com.budgetella.app.data.auth.AuthRepository
import com.budgetella.app.data.auth.AuthResult
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/** Which sub-screen the auth flow is showing. */
enum class AuthMode { Welcome, SignIn, SignUp, ForgotPassword }

/** Snapshot used by every auth-flow screen. */
data class AuthUiState(
    val mode: AuthMode = AuthMode.Welcome,
    val name: String = "",
    val email: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    /** Localised error string resource — null when no error. */
    @StringRes val errorRes: Int? = null,
    /** Set when the reset-password email has been sent. */
    val passwordResetSent: Boolean = false,
)

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(AuthUiState())
    val state: StateFlow<AuthUiState> = _state.asStateFlow()

    // ── Navigation ────────────────────────────────────────────────────────

    fun goTo(mode: AuthMode) {
        _state.update {
            it.copy(mode = mode, errorRes = null, passwordResetSent = false)
        }
    }

    // ── Field edits ───────────────────────────────────────────────────────

    fun onNameChange(value: String) = _state.update { it.copy(name = value, errorRes = null) }
    fun onEmailChange(value: String) = _state.update { it.copy(email = value, errorRes = null) }
    fun onPasswordChange(value: String) = _state.update { it.copy(password = value, errorRes = null) }

    // ── Actions ───────────────────────────────────────────────────────────

    fun submitSignIn() = withLoading {
        val s = _state.value
        if (!s.email.isValidEmail()) return@withLoading AuthResult.Failure(AuthError.InvalidEmail)
        authRepository.signInEmailPassword(s.email, s.password)
    }

    fun submitSignUp() = withLoading {
        val s = _state.value
        if (!s.email.isValidEmail()) return@withLoading AuthResult.Failure(AuthError.InvalidEmail)
        if (s.password.length < 8) return@withLoading AuthResult.Failure(AuthError.WeakPassword)
        authRepository.signUpEmailPassword(s.email, s.password, s.name)
    }

    fun submitForgotPassword() = withLoading {
        val s = _state.value
        if (!s.email.isValidEmail()) return@withLoading AuthResult.Failure(AuthError.InvalidEmail)
        authRepository.sendPasswordReset(s.email).also {
            if (it is AuthResult.Success) _state.update { st -> st.copy(passwordResetSent = true) }
        }
    }

    fun submitGoogleSignIn(activity: ComponentActivity) = withLoading {
        authRepository.signInWithGoogle(activity)
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private fun withLoading(block: suspend () -> AuthResult) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, errorRes = null) }
            val result = block()
            _state.update {
                it.copy(
                    isLoading = false,
                    errorRes = (result as? AuthResult.Failure)?.error?.toStringRes(),
                )
            }
        }
    }

    private fun String.isValidEmail(): Boolean =
        android.util.Patterns.EMAIL_ADDRESS.matcher(trim()).matches()

    private fun AuthError.toStringRes(): Int = when (this) {
        AuthError.InvalidCredentials -> R.string.auth_error_invalid_credentials
        AuthError.EmailAlreadyInUse  -> R.string.auth_error_email_in_use
        AuthError.WeakPassword       -> R.string.auth_error_weak_password
        AuthError.InvalidEmail       -> R.string.auth_error_invalid_email
        AuthError.NetworkUnavailable -> R.string.auth_error_network
        AuthError.NotConfigured      -> R.string.auth_error_not_configured
        AuthError.UserCancelled      -> R.string.auth_error_unknown      // silent — UI ignores anyway
        AuthError.Unknown            -> R.string.auth_error_unknown
    }
}
