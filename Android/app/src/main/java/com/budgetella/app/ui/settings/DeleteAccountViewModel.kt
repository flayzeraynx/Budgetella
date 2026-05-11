package com.budgetella.app.ui.settings

import androidx.lifecycle.ViewModel
import com.budgetella.app.data.auth.AuthRepository
import com.budgetella.app.data.auth.AuthResult
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

/**
 * Thin facade over [AuthRepository] for the delete-account flow. Lives in
 * its own VM so the dialog state isn't entangled with SettingsViewModel.
 */
@HiltViewModel
class DeleteAccountViewModel @Inject constructor(
    private val authRepository: AuthRepository,
) : ViewModel() {

    suspend fun deleteAccount(): AuthResult = authRepository.deleteAccount()

    suspend fun reauthenticate(password: String): AuthResult =
        authRepository.reauthenticateWithPassword(password)
}
