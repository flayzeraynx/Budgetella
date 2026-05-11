package com.budgetella.app.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Backup
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import com.budgetella.app.data.auth.AuthError
import com.budgetella.app.data.auth.AuthResult
import kotlinx.coroutines.launch

/**
 * Account-deletion sheet — port of iOS DeleteAccountView. Walks the user
 * through:
 *   1. a warning card explaining the destructive scope,
 *   2. an itemised list of data that gets wiped,
 *   3. a nudge to take a backup first,
 *   4. a typed-confirmation field ("delete"/"sil"),
 *   5. a separate password sheet if Firebase needs a fresh login.
 *
 * On success the user lands back at the AuthFlow because the auth listener
 * fires SignedOut after `user.delete()` completes.
 */
@Composable
fun DeleteAccountSheet(
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val vm: DeleteAccountViewModel = hiltViewModel()
    val scope = rememberCoroutineScope()

    var confirmText by remember { mutableStateOf("") }
    var isDeleting by remember { mutableStateOf(false) }
    var showReAuth by remember { mutableStateOf(false) }
    var errorText by remember { mutableStateOf<String?>(null) }

    val confirmKeyword = stringResource(R.string.delete_account_confirm_keyword)
    val canDelete = confirmText.trim().lowercase() == confirmKeyword.lowercase()

    suspend fun performDelete() {
        isDeleting = true
        errorText = null
        val result = vm.deleteAccount()
        isDeleting = false
        when (result) {
            AuthResult.Success -> onDismiss()
            is AuthResult.Failure -> when (result.error) {
                AuthError.RecentLoginRequired -> showReAuth = true
                AuthError.NetworkUnavailable -> errorText = "Offline."
                else -> errorText = "Couldn't delete account. Try again."
            }
        }
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(BrandColor.background()),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.xl)
                .padding(top = Spacing.md, bottom = Spacing.xxl),
            verticalArrangement = Arrangement.spacedBy(Spacing.lg),
        ) {
            Text(
                text = stringResource(R.string.delete_account_title),
                style = BrandText.largeTitle,
                color = BrandColor.textPrimary(),
            )

            // 1. Warning card
            WarningCard()

            // 2. Data list
            DataLossSection()

            // 3. Backup nudge
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(horizontal = 4.dp),
            ) {
                Icon(
                    imageVector = Icons.Filled.Backup,
                    contentDescription = null,
                    tint = BrandColor.Primary,
                    modifier = Modifier.size(16.dp),
                )
                Spacer(Modifier.width(Spacing.sm))
                Text(
                    text = stringResource(R.string.delete_account_backup_nudge),
                    style = BrandText.footnote,
                    color = BrandColor.textSecondary(),
                )
            }

            // 4. Danger zone — confirm input + button
            DangerZone(
                confirmText = confirmText,
                onConfirmChange = { confirmText = it },
                canDelete = canDelete,
                isDeleting = isDeleting,
                onDelete = { scope.launch { performDelete() } },
            )

            errorText?.let {
                Text(
                    text = it,
                    style = BrandText.footnote,
                    color = BrandColor.Expense,
                )
            }
        }
    }

    if (showReAuth) {
        ReAuthDialog(
            onDismiss = { showReAuth = false },
            onConfirm = { password ->
                scope.launch {
                    val reAuth = vm.reauthenticate(password)
                    if (reAuth is AuthResult.Success) {
                        showReAuth = false
                        performDelete()
                    } else {
                        // Wrong password handled inside ReAuthDialog state.
                    }
                }
            },
            vm = vm,
        )
    }
}

@Composable
private fun WarningCard() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(BrandColor.Expense.copy(alpha = 0.08f))
            .border(
                width = 1.dp,
                color = BrandColor.Expense.copy(alpha = 0.25f),
                shape = RoundedCornerShape(Spacing.radiusMedium),
            )
            .padding(Spacing.md),
        verticalAlignment = Alignment.Top,
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(BrandColor.Expense.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = Icons.Filled.Warning,
                contentDescription = null,
                tint = BrandColor.Expense,
                modifier = Modifier.size(18.dp),
            )
        }
        Spacer(Modifier.width(Spacing.md))
        Column {
            Text(
                text = stringResource(R.string.delete_account_irreversible_title),
                style = BrandText.headline,
                color = BrandColor.Expense,
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = stringResource(R.string.delete_account_irreversible_body),
                style = BrandText.footnote,
                color = BrandColor.textSecondary(),
            )
        }
    }
}

@Composable
private fun DataLossSection() {
    Column(verticalArrangement = Arrangement.spacedBy(Spacing.sm)) {
        Text(
            text = stringResource(R.string.delete_account_section_data),
            style = BrandText.caption,
            color = BrandColor.textTertiary(),
            modifier = Modifier.padding(horizontal = 4.dp),
        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Spacing.radiusMedium))
                .background(BrandColor.surface().copy(alpha = 0.4f)),
        ) {
            DataLossItem(stringResource(R.string.delete_account_item_transactions))
            DataLossDivider()
            DataLossItem(stringResource(R.string.delete_account_item_categories))
            DataLossDivider()
            DataLossItem(stringResource(R.string.delete_account_item_budgets))
            DataLossDivider()
            DataLossItem(stringResource(R.string.delete_account_item_ai))
            DataLossDivider()
            DataLossItem(stringResource(R.string.delete_account_item_cloud))
            DataLossDivider()
            DataLossItem(stringResource(R.string.delete_account_item_profile))
        }
    }
}

@Composable
private fun DataLossItem(label: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.md, vertical = Spacing.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(20.dp)
                .clip(CircleShape)
                .background(BrandColor.Expense.copy(alpha = 0.1f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = Icons.Filled.Close,
                contentDescription = null,
                tint = BrandColor.Expense,
                modifier = Modifier.size(11.dp),
            )
        }
        Spacer(Modifier.width(Spacing.md))
        Text(
            text = label,
            style = BrandText.subheadline,
            color = BrandColor.textPrimary(),
        )
    }
}

@Composable
private fun DataLossDivider() {
    Box(
        modifier = Modifier
            .padding(start = 52.dp)
            .fillMaxWidth()
            .height(0.5.dp)
            .background(BrandColor.borderSubtle()),
    )
}

@Composable
private fun DangerZone(
    confirmText: String,
    onConfirmChange: (String) -> Unit,
    canDelete: Boolean,
    isDeleting: Boolean,
    onDelete: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(Spacing.sm)) {
        Text(
            text = stringResource(R.string.delete_account_section_danger),
            style = BrandText.caption,
            color = BrandColor.Expense.copy(alpha = 0.7f),
            modifier = Modifier.padding(horizontal = 4.dp),
        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Spacing.radiusMedium))
                .background(BrandColor.Expense.copy(alpha = 0.05f))
                .border(
                    width = 1.dp,
                    color = BrandColor.Expense.copy(alpha = 0.15f),
                    shape = RoundedCornerShape(Spacing.radiusMedium),
                )
                .padding(Spacing.md),
            verticalArrangement = Arrangement.spacedBy(Spacing.md),
        ) {
            Text(
                text = stringResource(R.string.delete_account_confirm_prompt),
                style = BrandText.footnote,
                color = BrandColor.textSecondary(),
            )
            OutlinedTextField(
                value = confirmText,
                onValueChange = onConfirmChange,
                singleLine = true,
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Text,
                    capitalization = KeyboardCapitalization.None,
                    imeAction = ImeAction.Done,
                ),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(10.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = BrandColor.Expense.copy(alpha = 0.5f),
                    unfocusedBorderColor = BrandColor.borderSubtle(),
                    cursorColor = BrandColor.Expense,
                    focusedTextColor = BrandColor.textPrimary(),
                    unfocusedTextColor = BrandColor.textPrimary(),
                ),
            )
            Button(
                onClick = onDelete,
                enabled = canDelete && !isDeleting,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = BrandColor.Expense,
                    disabledContainerColor = BrandColor.Expense.copy(alpha = 0.3f),
                    contentColor = Color.White,
                    disabledContentColor = Color.White,
                ),
                contentPadding = PaddingValues(horizontal = Spacing.md),
            ) {
                if (isDeleting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(18.dp),
                        strokeWidth = 2.dp,
                        color = Color.White,
                    )
                    Spacer(Modifier.width(Spacing.sm))
                    Text(
                        text = stringResource(R.string.delete_account_cta_deleting),
                        style = BrandText.subheadline,
                    )
                } else {
                    Icon(
                        imageVector = Icons.Filled.Delete,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                    )
                    Spacer(Modifier.width(Spacing.sm))
                    Text(
                        text = stringResource(R.string.delete_account_cta),
                        style = BrandText.subheadline,
                    )
                }
            }
        }
    }
}

@Composable
private fun ReAuthDialog(
    onDismiss: () -> Unit,
    onConfirm: (String) -> Unit,
    vm: DeleteAccountViewModel,
) {
    var password by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    var isBusy by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val wrongPasswordText = stringResource(R.string.delete_account_reauth_wrong_password)

    AlertDialog(
        onDismissRequest = { if (!isBusy) onDismiss() },
        icon = {
            Icon(
                imageVector = Icons.Filled.Lock,
                contentDescription = null,
                tint = BrandColor.Primary,
            )
        },
        title = {
            Text(
                text = stringResource(R.string.delete_account_reauth_title),
                style = BrandText.title,
            )
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                Text(
                    text = stringResource(R.string.delete_account_reauth_body),
                    style = BrandText.body,
                    color = BrandColor.textSecondary(),
                )
                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it; error = null },
                    singleLine = true,
                    visualTransformation = PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Password,
                        imeAction = ImeAction.Done,
                    ),
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                )
                if (error != null) {
                    Text(
                        text = error.orEmpty(),
                        style = BrandText.footnote,
                        color = BrandColor.Expense,
                    )
                }
            }
        },
        confirmButton = {
            TextButton(
                enabled = password.isNotBlank() && !isBusy,
                onClick = {
                    scope.launch {
                        isBusy = true
                        val r = vm.reauthenticate(password)
                        isBusy = false
                        if (r is AuthResult.Success) {
                            onConfirm(password)
                        } else {
                            error = wrongPasswordText
                        }
                    }
                },
            ) {
                Text(
                    text = stringResource(R.string.delete_account_reauth_cta),
                    color = BrandColor.Expense,
                )
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss, enabled = !isBusy) {
                Text(stringResource(R.string.common_cancel))
            }
        },
        containerColor = BrandColor.surface(),
    )
}
