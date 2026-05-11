package com.budgetella.app.ui.settings

import android.content.Intent
import android.provider.Settings
import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsOff
import androidx.compose.material.icons.filled.Summarize
import androidx.compose.material.icons.filled.WarningAmber
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
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
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing

/**
 * Notification settings — port of iOS NotificationSettingsView.
 * Surfaces the four push toggles backed by [NotificationPrefs] DataStore.
 */
@Composable
fun NotificationSettingsSheet(
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val vm: NotificationSettingsViewModel = hiltViewModel()
    val state by vm.state.collectAsStateWithLifecycle()
    val context = LocalContext.current

    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(BrandColor.background()),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.lg)
                .padding(top = Spacing.md, bottom = Spacing.xxl),
            verticalArrangement = Arrangement.spacedBy(Spacing.lg),
        ) {
            Text(
                text = stringResource(R.string.notif_settings_title),
                style = BrandText.largeTitle,
                color = BrandColor.textPrimary(),
            )

            // Master toggle
            Section {
                NotifToggleRow(
                    icon = Icons.Filled.Notifications,
                    tint = BrandColor.Primary,
                    title = stringResource(R.string.notif_master_title),
                    subtitle = stringResource(R.string.notif_master_subtitle),
                    checked = state.allEnabled,
                    onChange = vm::setAllEnabled,
                )
            }
            Text(
                text = stringResource(R.string.notif_master_footer),
                style = BrandText.caption,
                color = BrandColor.textTertiary(),
                modifier = Modifier.padding(horizontal = Spacing.md),
            )

            // Individual toggles
            SectionHeader(stringResource(R.string.notif_section_types))
            Section {
                NotifToggleRow(
                    icon = Icons.Filled.Summarize,
                    tint = BrandColor.Info,
                    title = stringResource(R.string.notif_weekly_title),
                    subtitle = stringResource(R.string.notif_weekly_subtitle),
                    checked = state.weeklyDigest && state.allEnabled,
                    enabled = state.allEnabled,
                    onChange = vm::setWeeklyDigest,
                )
                Divider()
                NotifToggleRow(
                    icon = Icons.Filled.WarningAmber,
                    tint = BrandColor.Warning,
                    title = stringResource(R.string.notif_anomaly_title),
                    subtitle = stringResource(R.string.notif_anomaly_subtitle),
                    checked = state.anomalyAlerts && state.allEnabled,
                    enabled = state.allEnabled,
                    onChange = vm::setAnomalyAlerts,
                )
                Divider()
                NotifToggleRow(
                    icon = Icons.Filled.Lightbulb,
                    tint = BrandColor.Income,
                    title = stringResource(R.string.notif_savings_title),
                    subtitle = stringResource(R.string.notif_savings_subtitle),
                    checked = state.savingsSuggestions && state.allEnabled,
                    enabled = state.allEnabled,
                    onChange = vm::setSavingsSuggestions,
                )
            }

            // System-permission nudge — Android 13+ can have OS-level
            // notifications denied even if our in-app toggle is on. We can't
            // easily detect the precise OS state from here without a runtime
            // permission check, so we offer a direct deep-link to the system
            // notification settings as a one-tap escape hatch.
            TextButton(
                onClick = {
                    val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                    runCatching { context.startActivity(intent) }
                },
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Filled.NotificationsOff,
                        contentDescription = null,
                        tint = BrandColor.Warning,
                        modifier = Modifier.size(18.dp),
                    )
                    Spacer(Modifier.width(Spacing.sm))
                    Text(
                        text = stringResource(R.string.notif_open_system_settings),
                        style = BrandText.subheadline,
                        color = BrandColor.Primary,
                    )
                }
            }
        }
    }
}

@Composable
private fun SectionHeader(label: String) {
    Text(
        text = label,
        style = BrandText.caption2,
        color = BrandColor.textTertiary(),
        modifier = Modifier.padding(start = Spacing.md, top = Spacing.xs, bottom = Spacing.xs),
    )
}

@Composable
private fun Section(content: @Composable () -> Unit) {
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
private fun Divider() {
    Box(
        modifier = Modifier
            .padding(start = 58.dp, end = Spacing.md)
            .fillMaxWidth()
            .height(0.5.dp)
            .background(BrandColor.borderSubtle()),
    )
}

@Composable
private fun NotifToggleRow(
    icon: ImageVector,
    tint: Color,
    title: String,
    subtitle: String,
    checked: Boolean,
    onChange: (Boolean) -> Unit,
    enabled: Boolean = true,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = Spacing.sm, horizontal = Spacing.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(30.dp)
                .clip(RoundedCornerShape(Spacing.radiusSmall))
                .background(tint.copy(alpha = if (enabled) 0.18f else 0.08f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = tint.copy(alpha = if (enabled) 1f else 0.5f),
                modifier = Modifier.size(18.dp),
            )
        }
        Spacer(Modifier.width(Spacing.md))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = BrandText.body,
                fontWeight = FontWeight.Medium,
                color = if (enabled) BrandColor.textPrimary() else BrandColor.textTertiary(),
            )
            Text(
                text = subtitle,
                style = BrandText.caption,
                color = BrandColor.textTertiary(),
            )
        }
        Switch(
            checked = checked,
            onCheckedChange = onChange,
            enabled = enabled,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = BrandColor.Primary,
                uncheckedThumbColor = Color.White,
                uncheckedTrackColor = BrandColor.borderMedium(),
            ),
        )
    }
}
