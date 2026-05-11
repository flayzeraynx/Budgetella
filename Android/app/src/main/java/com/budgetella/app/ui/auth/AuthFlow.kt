package com.budgetella.app.ui.auth

import androidx.activity.ComponentActivity
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
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
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing

/**
 * Auth entry point — Welcome → SignIn / SignUp / Forgot. State lives in
 * [AuthViewModel]; the AppRoot router exits this composable automatically
 * the moment FirebaseAuth reports a SignedIn state.
 */
@Composable
fun AuthFlow() {
    val viewModel: AuthViewModel = hiltViewModel()
    val state by viewModel.state.collectAsState()
    // LocalActivity isn't available in androidx.activity-compose 1.9.3 yet, so
    // walk up from LocalContext. MainActivity is a ComponentActivity, so this
    // cast succeeds at runtime.
    val activity = LocalContext.current as? ComponentActivity

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BrandColor.background())
            .statusBarsPadding()
    ) {
        AnimatedContent(
            targetState = state.mode,
            label = "authMode",
            transitionSpec = {
                val forward = targetState.ordinal > initialState.ordinal
                val slide = if (forward) 64 else -64
                (slideInHorizontally(animationSpec = tween(220)) { slide } + fadeIn(tween(220))) togetherWith
                (slideOutHorizontally(animationSpec = tween(180)) { -slide } + fadeOut(tween(180)))
            }
        ) { mode ->
            when (mode) {
                AuthMode.Welcome -> WelcomeScreen(state, viewModel, activity)
                AuthMode.SignIn -> SignInScreen(state, viewModel)
                AuthMode.SignUp -> SignUpScreen(state, viewModel)
                AuthMode.ForgotPassword -> ForgotPasswordScreen(state, viewModel)
            }
        }
    }
}

// ── Welcome ────────────────────────────────────────────────────────────────

@Composable
private fun WelcomeScreen(
    state: AuthUiState,
    vm: AuthViewModel,
    activity: ComponentActivity?,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Spacing.xl)
            .padding(bottom = Spacing.xl)
            .navigationBarsPadding(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.weight(1f))

        androidx.compose.foundation.Image(
            painter = painterResource(R.mipmap.ic_launcher_foreground),
            contentDescription = null,
            modifier = Modifier.size(120.dp)
        )
        Spacer(Modifier.height(Spacing.lg))
        Text(
            text = stringResource(R.string.auth_welcome_title),
            style = BrandText.title,
            color = BrandColor.textPrimary(),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(Spacing.sm))
        Text(
            text = stringResource(R.string.auth_welcome_subtitle),
            style = BrandText.body,
            color = BrandColor.textSecondary(),
            textAlign = TextAlign.Center,
        )

        Spacer(Modifier.weight(1f))

        OutlinedButton(
            onClick = { activity?.let(vm::submitGoogleSignIn) },
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
            shape = RoundedCornerShape(Spacing.radiusFull),
            enabled = !state.isLoading && activity != null,
        ) {
            Text(
                text = stringResource(R.string.auth_continue_with_google),
                style = BrandText.subheadline,
                color = BrandColor.textPrimary(),
            )
        }
        Spacer(Modifier.height(Spacing.md))
        Button(
            onClick = { vm.goTo(AuthMode.SignIn) },
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
            shape = RoundedCornerShape(Spacing.radiusFull),
            colors = ButtonDefaults.buttonColors(containerColor = BrandColor.Primary),
            enabled = !state.isLoading,
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Filled.Email,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp),
                )
                Spacer(Modifier.width(Spacing.sm))
                Text(
                    text = stringResource(R.string.auth_continue_with_email),
                    style = BrandText.subheadline,
                )
            }
        }

        Spacer(Modifier.height(Spacing.lg))
        Text(
            text = stringResource(R.string.auth_terms_notice),
            style = BrandText.caption,
            color = BrandColor.textTertiary(),
            textAlign = TextAlign.Center,
        )

        // Inline error (Google sign-in failures, network, etc.).
        state.errorRes?.let { res ->
            Spacer(Modifier.height(Spacing.md))
            ErrorBanner(messageRes = res)
        }
    }
}

// ── Sign In ────────────────────────────────────────────────────────────────

@Composable
private fun SignInScreen(state: AuthUiState, vm: AuthViewModel) {
    AuthFormScaffold(
        title = stringResource(R.string.auth_signin_title),
        onBack = { vm.goTo(AuthMode.Welcome) },
    ) {
        BrandTextField(
            value = state.email,
            onValueChange = vm::onEmailChange,
            labelRes = R.string.auth_email_label,
            keyboardType = KeyboardType.Email,
            imeAction = ImeAction.Next,
        )
        Spacer(Modifier.height(Spacing.md))
        BrandTextField(
            value = state.password,
            onValueChange = vm::onPasswordChange,
            labelRes = R.string.auth_password_label,
            keyboardType = KeyboardType.Password,
            imeAction = ImeAction.Done,
            isPassword = true,
        )
        TextButton(onClick = { vm.goTo(AuthMode.ForgotPassword) }) {
            Text(
                text = stringResource(R.string.auth_forgot_password_link),
                style = BrandText.footnote,
                color = BrandColor.Primary,
            )
        }
        Spacer(Modifier.height(Spacing.md))
        PrimaryCtaButton(
            label = stringResource(R.string.auth_signin_cta),
            loading = state.isLoading,
            onClick = vm::submitSignIn,
        )
        Spacer(Modifier.height(Spacing.lg))
        AuthSwitchFooter(
            question = stringResource(R.string.auth_no_account_question),
            action = stringResource(R.string.auth_no_account_action),
            onClick = { vm.goTo(AuthMode.SignUp) },
        )
        state.errorRes?.let {
            Spacer(Modifier.height(Spacing.md))
            ErrorBanner(messageRes = it)
        }
    }
}

// ── Sign Up ────────────────────────────────────────────────────────────────

@Composable
private fun SignUpScreen(state: AuthUiState, vm: AuthViewModel) {
    AuthFormScaffold(
        title = stringResource(R.string.auth_signup_title),
        onBack = { vm.goTo(AuthMode.Welcome) },
    ) {
        BrandTextField(
            value = state.name,
            onValueChange = vm::onNameChange,
            labelRes = R.string.auth_name_label,
            keyboardType = KeyboardType.Text,
            imeAction = ImeAction.Next,
        )
        Spacer(Modifier.height(Spacing.md))
        BrandTextField(
            value = state.email,
            onValueChange = vm::onEmailChange,
            labelRes = R.string.auth_email_label,
            keyboardType = KeyboardType.Email,
            imeAction = ImeAction.Next,
        )
        Spacer(Modifier.height(Spacing.md))
        BrandTextField(
            value = state.password,
            onValueChange = vm::onPasswordChange,
            labelRes = R.string.auth_password_label,
            keyboardType = KeyboardType.Password,
            imeAction = ImeAction.Done,
            isPassword = true,
        )
        Spacer(Modifier.height(Spacing.lg))
        PrimaryCtaButton(
            label = stringResource(R.string.auth_signup_cta),
            loading = state.isLoading,
            onClick = vm::submitSignUp,
        )
        Spacer(Modifier.height(Spacing.md))
        Text(
            text = stringResource(R.string.auth_terms_notice),
            style = BrandText.caption,
            color = BrandColor.textTertiary(),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(Spacing.lg))
        AuthSwitchFooter(
            question = stringResource(R.string.auth_have_account_question),
            action = stringResource(R.string.auth_have_account_action),
            onClick = { vm.goTo(AuthMode.SignIn) },
        )
        state.errorRes?.let {
            Spacer(Modifier.height(Spacing.md))
            ErrorBanner(messageRes = it)
        }
    }
}

// ── Forgot Password ────────────────────────────────────────────────────────

@Composable
private fun ForgotPasswordScreen(state: AuthUiState, vm: AuthViewModel) {
    AuthFormScaffold(
        title = stringResource(R.string.auth_forgot_title),
        onBack = { vm.goTo(AuthMode.SignIn) },
    ) {
        Text(
            text = stringResource(R.string.auth_forgot_body),
            style = BrandText.body,
            color = BrandColor.textSecondary(),
        )
        Spacer(Modifier.height(Spacing.lg))
        BrandTextField(
            value = state.email,
            onValueChange = vm::onEmailChange,
            labelRes = R.string.auth_email_label,
            keyboardType = KeyboardType.Email,
            imeAction = ImeAction.Done,
        )
        Spacer(Modifier.height(Spacing.lg))
        PrimaryCtaButton(
            label = stringResource(R.string.auth_forgot_send),
            loading = state.isLoading,
            onClick = vm::submitForgotPassword,
        )
        if (state.passwordResetSent) {
            Spacer(Modifier.height(Spacing.md))
            Text(
                text = stringResource(R.string.auth_forgot_sent),
                style = BrandText.body,
                color = BrandColor.Income,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
        }
        state.errorRes?.let {
            Spacer(Modifier.height(Spacing.md))
            ErrorBanner(messageRes = it)
        }
    }
}

// ── Shared scaffolds + atoms ───────────────────────────────────────────────

@Composable
private fun AuthFormScaffold(
    title: String,
    onBack: () -> Unit,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Spacing.xl)
            .padding(bottom = Spacing.xl)
            .navigationBarsPadding(),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = stringResource(R.string.auth_back),
                    tint = BrandColor.textPrimary(),
                )
            }
        }
        Spacer(Modifier.height(Spacing.md))
        Text(
            text = title,
            style = BrandText.title,
            color = BrandColor.textPrimary(),
        )
        Spacer(Modifier.height(Spacing.xl))
        content(this)
    }
}

@Composable
private fun BrandTextField(
    value: String,
    onValueChange: (String) -> Unit,
    @androidx.annotation.StringRes labelRes: Int,
    keyboardType: KeyboardType,
    imeAction: ImeAction,
    isPassword: Boolean = false,
) {
    // Password visibility toggles per-field — survives recomposition.
    var passwordVisible by remember { mutableStateOf(false) }
    val showPasswordCd = stringResource(R.string.auth_show_password)
    val hidePasswordCd = stringResource(R.string.auth_hide_password)

    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(stringResource(labelRes), style = BrandText.footnote) },
        singleLine = true,
        keyboardOptions = KeyboardOptions(
            keyboardType = keyboardType,
            imeAction = imeAction,
        ),
        visualTransformation = when {
            !isPassword -> androidx.compose.ui.text.input.VisualTransformation.None
            passwordVisible -> androidx.compose.ui.text.input.VisualTransformation.None
            else -> PasswordVisualTransformation()
        },
        trailingIcon = if (isPassword) {
            {
                IconButton(onClick = { passwordVisible = !passwordVisible }) {
                    Icon(
                        imageVector = if (passwordVisible) Icons.Filled.VisibilityOff else Icons.Filled.Visibility,
                        contentDescription = if (passwordVisible) hidePasswordCd else showPasswordCd,
                        tint = BrandColor.textTertiary(),
                    )
                }
            }
        } else null,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(Spacing.radiusMedium),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = BrandColor.Primary,
            unfocusedBorderColor = BrandColor.borderMedium(),
            focusedLabelColor = BrandColor.Primary,
            cursorColor = BrandColor.Primary,
            focusedTextColor = BrandColor.textPrimary(),
            unfocusedTextColor = BrandColor.textPrimary(),
        ),
    )
}

@Composable
private fun PrimaryCtaButton(
    label: String,
    loading: Boolean,
    onClick: () -> Unit,
) {
    Button(
        onClick = onClick,
        enabled = !loading,
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp),
        shape = RoundedCornerShape(Spacing.radiusFull),
        colors = ButtonDefaults.buttonColors(containerColor = BrandColor.Primary),
    ) {
        if (loading) {
            CircularProgressIndicator(
                modifier = Modifier.size(20.dp),
                strokeWidth = 2.dp,
                color = Color.White,
            )
        } else {
            Text(text = label, style = BrandText.subheadline)
        }
    }
}

@Composable
private fun AuthSwitchFooter(question: String, action: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text = question, style = BrandText.footnote, color = BrandColor.textTertiary())
        TextButton(onClick = onClick) {
            Text(text = action, style = BrandText.footnote, color = BrandColor.Primary)
        }
    }
}

@Composable
private fun ErrorBanner(@androidx.annotation.StringRes messageRes: Int) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(BrandColor.Expense.copy(alpha = 0.12f))
            .padding(Spacing.md)
    ) {
        Text(
            text = stringResource(messageRes),
            style = BrandText.footnote,
            color = BrandColor.Expense,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

