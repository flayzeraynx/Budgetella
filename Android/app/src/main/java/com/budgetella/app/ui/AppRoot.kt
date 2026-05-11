package com.budgetella.app.ui

import android.widget.Toast
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.hilt.navigation.compose.hiltViewModel
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.data.backup.BackupService
import com.budgetella.app.data.prefs.UserPrefs
import com.budgetella.app.ui.auth.AuthFlow
import com.budgetella.app.ui.biometric.BiometricLockScreen
import com.budgetella.app.ui.main.MainScaffold
import com.budgetella.app.ui.onboarding.OnboardingFlow
import com.budgetella.app.ui.settings.rememberBackupExportLauncher
import com.budgetella.app.ui.settings.rememberBackupImportLauncher
import com.budgetella.app.ui.splash.SplashScreen
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.components.SingletonComponent

/**
 * Top-level router — Splash → Onboarding → Auth → BiometricLock → Main.
 * Crossfaded between states so transitions never flash.
 */
@Composable
fun AppRoot() {
    val viewModel: AppRootViewModel = hiltViewModel()
    val state by viewModel.state.collectAsState()

    // Hilt entry-point hop — pulls BackupService + UserPrefs out of the
    // SingletonComponent so the backup launchers (which must be @Composable)
    // can call them without going through a dedicated ViewModel.
    val context = LocalContext.current
    val entryPoint = remember(context) {
        EntryPointAccessors.fromApplication(context, AppRootEntryPoint::class.java)
    }

    val exportToast = stringResource(R.string.backup_export_done)
    val exportError = stringResource(R.string.backup_export_failed)
    val importDoneTemplate = stringResource(R.string.backup_import_done)
    val importError = stringResource(R.string.backup_import_failed)

    val onExport = rememberBackupExportLauncher(
        backupService = entryPoint.backupService(),
        userPrefs = entryPoint.userPrefs(),
        onResult = { ok ->
            Toast.makeText(
                context,
                if (ok) exportToast else exportError,
                Toast.LENGTH_SHORT
            ).show()
        }
    )
    val onImport = rememberBackupImportLauncher(
        backupService = entryPoint.backupService(),
        userPrefs = entryPoint.userPrefs(),
        onResult = { imported, skipped ->
            val message = if (imported == 0 && skipped == 0) importError
            else importDoneTemplate.format(imported, skipped)
            Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
        }
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BrandColor.background())
    ) {
        AnimatedContent(
            targetState = state,
            label = "appRoot",
            transitionSpec = {
                fadeIn(animationSpec = tween(220)) togetherWith fadeOut(animationSpec = tween(180))
            }
        ) { resolved ->
            when (resolved) {
                AppRootState.Splash -> SplashScreen()
                AppRootState.Onboarding -> OnboardingFlow(onFinished = viewModel::onOnboardingFinished)
                AppRootState.Auth -> AuthFlow()
                AppRootState.BiometricLock -> BiometricLockScreen(
                    onUnlocked = viewModel::onBiometricUnlocked,
                    onSignOut = viewModel::onBiometricSignOut,
                )
                AppRootState.Main -> MainScaffold(
                    onExportBackup = onExport,
                    onImportBackup = onImport,
                )
            }
        }
    }
}

/** Hilt entry point so the composable scope can pull these singletons. */
@EntryPoint
@InstallIn(SingletonComponent::class)
interface AppRootEntryPoint {
    fun backupService(): BackupService
    fun userPrefs(): UserPrefs
}

