package com.budgetella.app.ui.settings

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.HelpOutline
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.Paid
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Upload
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.budgetella.app.BuildConfig
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing

/**
 * Settings — port of iOS SettingsView.
 *
 * Hosted as a ModalBottomSheet by MainScaffold. All picker sheets and the
 * notification inbox are sibling sheets at MainScaffold scope (callbacks
 * dismiss this sheet first to avoid the nested-sheet trap).
 */
@Composable
fun SettingsScreen(
    onDismiss: () -> Unit,
    onShowTheme: () -> Unit,
    onShowLanguage: () -> Unit,
    onShowCurrency: () -> Unit,
    onExport: () -> Unit = {},
    onImport: () -> Unit = {},
    onShowInbox: () -> Unit,
    onShowProfile: () -> Unit = {},
    onDeleteAccount: () -> Unit = {},
    onShowNotificationSettings: () -> Unit = {},
    onShowCategories: () -> Unit = {},
    modifier: Modifier = Modifier,
) {
    val vm: SettingsViewModel = hiltViewModel()
    val state by vm.state.collectAsStateWithLifecycle()
    val context = LocalContext.current

    var confirmSignOut by remember { mutableStateOf(false) }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(BrandColor.background())
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.lg)
                .padding(top = Spacing.md, bottom = Spacing.xxl),
            verticalArrangement = Arrangement.spacedBy(Spacing.lg),
        ) {
            // Title
            Text(
                text = stringResource(R.string.settings_title),
                style = BrandText.largeTitle,
                color = BrandColor.textPrimary(),
                modifier = Modifier.padding(top = Spacing.sm, bottom = Spacing.xs),
            )

            // Profile card — tap opens the profile sheet
            ProfileCard(
                displayName = state.displayName,
                email = state.email,
                photoUrl = state.photoUrl,
                onClick = onShowProfile,
            )

            // Premium row
            SettingsGroup {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = Spacing.sm, horizontal = Spacing.md),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    IconBadge(icon = Icons.Filled.Star, tint = BrandColor.Warning)
                    Spacer(Modifier.width(Spacing.md))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = stringResource(R.string.settings_premium_label),
                            style = BrandText.body,
                            color = BrandColor.textPrimary(),
                        )
                        Text(
                            text = stringResource(
                                if (state.isPremium) R.string.settings_premium_subtitle_active
                                else R.string.settings_premium_subtitle_inactive
                            ),
                            style = BrandText.footnote,
                            color = BrandColor.textTertiary(),
                        )
                    }
                }
            }

            // Preferences
            SectionHeader(stringResource(R.string.settings_section_preferences))
            SettingsGroup {
                NavigationRow(
                    icon = Icons.Filled.Palette,
                    tint = BrandColor.Primary,
                    title = stringResource(R.string.settings_theme),
                    value = themeLabel(state.theme),
                    onClick = onShowTheme,
                )
                RowDivider()
                NavigationRow(
                    icon = Icons.Filled.Language,
                    tint = BrandColor.Info,
                    title = stringResource(R.string.settings_language),
                    value = state.language.displayName,
                    onClick = onShowLanguage,
                )
                RowDivider()
                NavigationRow(
                    icon = Icons.Filled.Paid,
                    tint = BrandColor.Income,
                    title = stringResource(R.string.settings_currency),
                    value = "${state.currency.symbol} ${state.currency.raw}",
                    onClick = onShowCurrency,
                )
            }

            // Security
            SectionHeader(stringResource(R.string.settings_section_security))
            SettingsGroup {
                ToggleRow(
                    icon = Icons.Filled.Fingerprint,
                    tint = BrandColor.Primary,
                    title = stringResource(R.string.settings_biometric),
                    checked = state.biometricLockEnabled,
                    onChange = vm::setBiometric,
                )
                RowDivider()
                ToggleRow(
                    icon = Icons.Filled.VisibilityOff,
                    tint = BrandColor.Info,
                    title = stringResource(R.string.settings_hide_amounts),
                    checked = state.hideAmounts,
                    onChange = vm::setHideAmounts,
                )
            }

            // Data
            SectionHeader(stringResource(R.string.settings_section_data))
            SettingsGroup {
                NavigationRow(
                    icon = Icons.Filled.Upload,
                    tint = BrandColor.Income,
                    title = stringResource(R.string.settings_export),
                    onClick = onExport,
                )
                RowDivider()
                NavigationRow(
                    icon = Icons.Filled.Download,
                    tint = BrandColor.Info,
                    title = stringResource(R.string.settings_import),
                    onClick = onImport,
                )
            }

            // Notifications
            SectionHeader(stringResource(R.string.settings_section_notifications))
            SettingsGroup {
                NavigationRow(
                    icon = Icons.Filled.Notifications,
                    tint = BrandColor.Warning,
                    title = stringResource(R.string.settings_notifications_inbox),
                    onClick = onShowInbox,
                )
                RowDivider()
                NavigationRow(
                    icon = Icons.Filled.Notifications,
                    tint = BrandColor.Primary,
                    title = stringResource(R.string.settings_notifications_push),
                    onClick = onShowNotificationSettings,
                )
            }

            // Support
            SectionHeader(stringResource(R.string.settings_section_support))
            SettingsGroup {
                NavigationRow(
                    icon = Icons.Filled.HelpOutline,
                    tint = BrandColor.Primary,
                    title = stringResource(R.string.settings_help),
                    onClick = {
                        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:support@budgetella.app"))
                        runCatching { context.startActivity(intent) }
                    },
                )
                RowDivider()
                NavigationRow(
                    icon = Icons.Filled.Lock,
                    tint = BrandColor.Info,
                    title = stringResource(R.string.settings_privacy),
                    onClick = {
                        runCatching {
                            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://budgetella.app/privacy")))
                        }
                    },
                )
                RowDivider()
                NavigationRow(
                    icon = Icons.Filled.Description,
                    tint = BrandColor.Info,
                    title = stringResource(R.string.settings_terms),
                    onClick = {
                        runCatching {
                            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://budgetella.app/terms")))
                        }
                    },
                )
            }

            // Account
            SectionHeader(stringResource(R.string.settings_section_account))
            SettingsGroup {
                NavigationRow(
                    icon = Icons.Filled.ExitToApp,
                    tint = BrandColor.Warning,
                    title = stringResource(R.string.settings_signout),
                    destructive = true,
                    onClick = { confirmSignOut = true },
                )
                RowDivider()
                NavigationRow(
                    icon = Icons.Filled.AccountCircle,
                    tint = BrandColor.Expense,
                    title = stringResource(R.string.settings_delete_account),
                    destructive = true,
                    onClick = onDeleteAccount,
                )
            }

            // Version footer
            Spacer(Modifier.height(Spacing.md))
            Text(
                text = "${stringResource(R.string.settings_version)} ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})",
                style = BrandText.footnote,
                color = BrandColor.textTertiary(),
                modifier = Modifier.fillMaxWidth().padding(Spacing.md),
            )
        }
    }

    if (confirmSignOut) {
        AlertDialog(
            onDismissRequest = { confirmSignOut = false },
            title = { Text(stringResource(R.string.settings_signout_confirm_title)) },
            text = { Text(stringResource(R.string.settings_signout_confirm_body)) },
            confirmButton = {
                TextButton(onClick = {
                    confirmSignOut = false
                    vm.signOut()
                    onDismiss()
                }) {
                    Text(stringResource(R.string.settings_signout), color = BrandColor.Expense)
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmSignOut = false }) {
                    Text(stringResource(R.string.common_cancel))
                }
            },
            containerColor = BrandColor.surface(),
        )
    }

}

// ── Building blocks ────────────────────────────────────────────────────────

@Composable
private fun SectionHeader(label: String) {
    Text(
        text = label.uppercase(),
        style = BrandText.caption2,
        color = BrandColor.textTertiary(),
        modifier = Modifier.padding(start = Spacing.md, top = Spacing.xs, bottom = Spacing.xs),
    )
}

@Composable
private fun SettingsGroup(content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(BrandColor.surface().copy(alpha = 0.4f))
            .padding(vertical = Spacing.xs),
    ) {
        content()
    }
}

@Composable
private fun RowDivider() {
    Box(
        modifier = Modifier
            .padding(start = 58.dp, end = Spacing.md)
            .fillMaxWidth()
            .height(0.5.dp)
            .background(BrandColor.borderSubtle()),
    )
}

@Composable
private fun IconBadge(icon: ImageVector, tint: Color) {
    Box(
        modifier = Modifier
            .size(30.dp)
            .clip(RoundedCornerShape(Spacing.radiusSmall))
            .background(tint.copy(alpha = 0.18f)),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = tint,
            modifier = Modifier.size(18.dp),
        )
    }
}

@Composable
private fun NavigationRow(
    icon: ImageVector,
    tint: Color,
    title: String,
    value: String? = null,
    destructive: Boolean = false,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = Spacing.md, horizontal = Spacing.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconBadge(icon = icon, tint = tint)
        Spacer(Modifier.width(Spacing.md))
        Text(
            text = title,
            style = BrandText.body,
            color = if (destructive) BrandColor.Expense else BrandColor.textPrimary(),
            modifier = Modifier.weight(1f),
        )
        if (value != null) {
            Text(
                text = value,
                style = BrandText.footnote,
                color = BrandColor.textTertiary(),
                modifier = Modifier.padding(end = Spacing.xs),
            )
        }
        Icon(
            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = BrandColor.textTertiary(),
            modifier = Modifier.size(20.dp),
        )
    }
}

@Composable
private fun ToggleRow(
    icon: ImageVector,
    tint: Color,
    title: String,
    checked: Boolean,
    onChange: (Boolean) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = Spacing.sm, horizontal = Spacing.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconBadge(icon = icon, tint = tint)
        Spacer(Modifier.width(Spacing.md))
        Text(
            text = title,
            style = BrandText.body,
            color = BrandColor.textPrimary(),
            modifier = Modifier.weight(1f),
        )
        Switch(
            checked = checked,
            onCheckedChange = onChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = BrandColor.Primary,
                uncheckedThumbColor = Color.White,
                uncheckedTrackColor = BrandColor.borderMedium(),
            ),
        )
    }
}

@Composable
private fun ProfileCard(
    displayName: String?,
    email: String?,
    photoUrl: String?,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(BrandColor.surface().copy(alpha = 0.4f))
            .clickable(onClick = onClick)
            .padding(Spacing.lg),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ProfileAvatar(photoUrl = photoUrl, size = 48.dp)
        Spacer(Modifier.width(Spacing.md))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = displayName?.takeIf { it.isNotBlank() } ?: (email ?: ""),
                style = BrandText.subheadline.copy(fontWeight = FontWeight.SemiBold),
                color = BrandColor.textPrimary(),
            )
            if (!email.isNullOrBlank()) {
                Text(
                    text = email,
                    style = BrandText.footnote,
                    color = BrandColor.textTertiary(),
                )
            }
        }
        Icon(
            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = BrandColor.textTertiary(),
            modifier = Modifier.size(20.dp),
        )
    }
}

/**
 * Avatar — renders the user's Google / Firebase photoUrl via Coil, falling back
 * to a tinted person glyph when no photo is available (email/password accounts
 * or sign-ups where Google didn't return a picture URL).
 */
@Composable
private fun ProfileAvatar(
    photoUrl: String?,
    size: androidx.compose.ui.unit.Dp,
) {
    Box(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .background(BrandColor.Primary.copy(alpha = 0.2f)),
        contentAlignment = Alignment.Center,
    ) {
        if (!photoUrl.isNullOrBlank()) {
            coil.compose.AsyncImage(
                model = photoUrl,
                contentDescription = null,
                modifier = Modifier
                    .size(size)
                    .clip(CircleShape),
                contentScale = androidx.compose.ui.layout.ContentScale.Crop,
            )
        } else {
            Icon(
                imageVector = Icons.Filled.AccountCircle,
                contentDescription = null,
                tint = BrandColor.Primary,
                modifier = Modifier.size((size.value * 0.6f).dp),
            )
        }
    }
}

@Composable
private fun themeLabel(theme: com.budgetella.app.data.model.AppTheme): String = when (theme) {
    com.budgetella.app.data.model.AppTheme.Dark -> stringResource(R.string.theme_dark)
    com.budgetella.app.data.model.AppTheme.Light -> stringResource(R.string.theme_light)
    com.budgetella.app.data.model.AppTheme.System -> stringResource(R.string.theme_system)
}
