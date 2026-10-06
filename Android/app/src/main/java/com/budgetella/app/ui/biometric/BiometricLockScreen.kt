package com.budgetella.app.ui.biometric

import android.os.Build
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_STRONG
import androidx.biometric.BiometricManager.Authenticators.DEVICE_CREDENTIAL
import androidx.biometric.BiometricPrompt
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing

/**
 * Full-screen biometric gate shown between AuthFlow and MainScaffold whenever
 * AppSettings.biometricLockEnabled is true and the user is signed in.
 *
 * Behaviour mirrors iOS LocalAuthenticationManager:
 *  - Prompt auto-launches on first render so the user goes straight from
 *    cold start into Face ID / fingerprint, no extra tap.
 *  - Failed attempts don't sign out — we just leave the prompt closed so the
 *    user can retry via the "Unlock" button.
 *  - "Sign out" is the explicit escape hatch when biometrics are misconfigured
 *    or the user wants to switch accounts.
 *
 * Requires the hosting activity to be a [FragmentActivity] (see MainActivity).
 */
@Composable
fun BiometricLockScreen(
    onUnlocked: () -> Unit,
    onSignOut: () -> Unit,
) {
    val context = LocalContext.current
    // Cast the host activity — MainActivity already extends FragmentActivity.
    // If this ever fails the screen renders without functioning auth, which
    // is the safest fallback (user can still hit Sign out).
    val activity = context as? FragmentActivity

    val title = stringResource(R.string.biometric_prompt_title)
    val subtitle = stringResource(R.string.biometric_prompt_subtitle)
    val unavailableMsg = stringResource(R.string.biometric_unavailable)

    // Device-credential (PIN/pattern) fallback can only be *combined* with a
    // biometric class from API 30 (R); below that BiometricPrompt rejects the
    // pairing and authenticate() fails silently. Drop to STRONG-only there.
    val allowedAuthenticators = remember {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) BIOMETRIC_STRONG or DEVICE_CREDENTIAL
        else BIOMETRIC_STRONG
    }

    // Can this device actually satisfy the lock *right now*? On an emulator (or
    // a phone with no fingerprint/PIN enrolled) this is NONE_ENROLLED/NO_HARDWARE
    // — in which case we must not brick the user behind a prompt that can never
    // succeed. They're already Firebase-authenticated; the biometric gate is a
    // local convenience lock, so we let them continue.
    val lockEnforceable = remember(activity, allowedAuthenticators) {
        activity != null &&
            BiometricManager.from(activity).canAuthenticate(allowedAuthenticators) ==
            BiometricManager.BIOMETRIC_SUCCESS
    }

    var errorMessage by remember { mutableStateOf<String?>(null) }

    val prompt = remember(activity) {
        activity?.let {
            BiometricPrompt(
                it,
                ContextCompat.getMainExecutor(it),
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(
                        result: BiometricPrompt.AuthenticationResult
                    ) {
                        onUnlocked()
                    }

                    override fun onAuthenticationError(
                        errorCode: Int,
                        errString: CharSequence,
                    ) {
                        // User-driven dismissals are silent — the user can retry
                        // via the Unlock button. Everything else (no hardware,
                        // nothing enrolled, lockout) gets surfaced so the screen
                        // is never a dead end.
                        errorMessage = when (errorCode) {
                            BiometricPrompt.ERROR_USER_CANCELED,
                            BiometricPrompt.ERROR_NEGATIVE_BUTTON,
                            BiometricPrompt.ERROR_CANCELED -> null
                            BiometricPrompt.ERROR_NO_BIOMETRICS,
                            BiometricPrompt.ERROR_HW_NOT_PRESENT,
                            BiometricPrompt.ERROR_HW_UNAVAILABLE,
                            BiometricPrompt.ERROR_NO_DEVICE_CREDENTIAL -> unavailableMsg
                            else -> errString.toString()
                        }
                    }
                    // onAuthenticationFailed (single non-fatal mismatch) stays
                    // ignored — the system prompt handles retry feedback itself.
                },
            )
        }
    }

    val promptInfo = remember(title, subtitle, allowedAuthenticators) {
        BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .setSubtitle(subtitle)
            .setAllowedAuthenticators(allowedAuthenticators)
            .build()
    }

    val authenticate: () -> Unit = remember(prompt, promptInfo) {
        { prompt?.authenticate(promptInfo) }
    }

    // Auto-launch once on first composition when the lock is actually
    // enforceable — matches iOS kicking off LAContext.evaluatePolicy in
    // .onAppear. When it isn't, show the explanation up front instead.
    LaunchedEffect(lockEnforceable) {
        if (lockEnforceable) authenticate() else errorMessage = unavailableMsg
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BrandColor.background())
            .statusBarsPadding()
            .navigationBarsPadding(),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = Spacing.xl),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween,
        ) {
            Spacer(modifier = Modifier.height(Spacing.xxl))

            // ── Brand mark ──────────────────────────────────────────────────
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Image(
                    painter = painterResource(id = R.mipmap.ic_launcher_foreground),
                    contentDescription = null,
                    modifier = Modifier
                        .size(120.dp)
                        .clip(RoundedCornerShape(Spacing.radiusLarge)),
                )
                Spacer(modifier = Modifier.height(Spacing.xl))
                Text(
                    text = title,
                    style = BrandText.title,
                    color = BrandColor.textPrimary(),
                    textAlign = TextAlign.Center,
                )
                Spacer(modifier = Modifier.height(Spacing.sm))
                Text(
                    text = subtitle,
                    style = BrandText.body,
                    color = BrandColor.textSecondary(),
                    textAlign = TextAlign.Center,
                )
            }

            // ── Action stack ────────────────────────────────────────────────
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                errorMessage?.let { msg ->
                    Text(
                        text = msg,
                        style = BrandText.footnote,
                        color = BrandColor.textSecondary(),
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth(),
                    )
                    Spacer(modifier = Modifier.height(Spacing.md))
                }
                Button(
                    // When the lock can be enforced this re-launches the system
                    // prompt; when it can't (no enrolled biometric/credential)
                    // it becomes a plain "Continue" so the user is never stuck.
                    onClick = if (lockEnforceable) authenticate else onUnlocked,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    shape = RoundedCornerShape(Spacing.radiusMedium),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = BrandColor.Primary,
                        contentColor = Color.White,
                    ),
                ) {
                    if (lockEnforceable) {
                        Icon(
                            imageVector = Icons.Filled.Fingerprint,
                            contentDescription = null,
                            modifier = Modifier.size(20.dp),
                        )
                        Spacer(modifier = Modifier.size(Spacing.sm))
                    }
                    Text(
                        text = stringResource(
                            if (lockEnforceable) R.string.biometric_unlock
                            else R.string.biometric_continue
                        ),
                        style = BrandText.subheadline,
                    )
                }
                Spacer(modifier = Modifier.height(Spacing.md))
                TextButton(onClick = onSignOut) {
                    Text(
                        text = stringResource(R.string.biometric_signout),
                        style = BrandText.footnote,
                        color = BrandColor.textTertiary(),
                    )
                }
                Spacer(modifier = Modifier.height(Spacing.lg))
            }
        }
    }
}

