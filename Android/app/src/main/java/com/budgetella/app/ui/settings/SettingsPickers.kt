package com.budgetella.app.ui.settings

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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Brightness4
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.filled.SettingsBrightness
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import com.budgetella.app.core.locale.LocaleHelper
import com.budgetella.app.data.model.AppCurrency
import com.budgetella.app.data.model.AppLanguage
import com.budgetella.app.data.model.AppTheme

/**
 * Compose body for the Theme / Language / Currency picker bottom sheets.
 *
 * Each one is intended to be wrapped in a ModalBottomSheet at MainScaffold
 * scope — they render the list of options + active checkmark and call the
 * appropriate VM setter on tap. The selectable identifier (enum case) is
 * compared via `==` so the active row stays consistent across rotations.
 */

@Composable
fun ThemePickerSheet(onDismiss: () -> Unit) {
    val vm: SettingsViewModel = hiltViewModel()
    val state by vm.state.collectAsStateWithLifecycle()
    val active = state.theme

    PickerColumn(title = stringResource(R.string.settings_theme)) {
        PickerRow(
            icon = Icons.Filled.Brightness4,
            label = stringResource(R.string.theme_dark),
            selected = active == AppTheme.Dark,
            onClick = { vm.setTheme(AppTheme.Dark); onDismiss() },
        )
        PickerRow(
            icon = Icons.Filled.LightMode,
            label = stringResource(R.string.theme_light),
            selected = active == AppTheme.Light,
            onClick = { vm.setTheme(AppTheme.Light); onDismiss() },
        )
        PickerRow(
            icon = Icons.Filled.SettingsBrightness,
            label = stringResource(R.string.theme_system),
            selected = active == AppTheme.System,
            onClick = { vm.setTheme(AppTheme.System); onDismiss() },
        )
    }
}

@Composable
fun LanguagePickerSheet(onDismiss: () -> Unit) {
    val vm: SettingsViewModel = hiltViewModel()
    val state by vm.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val active = state.language

    PickerColumn(title = stringResource(R.string.settings_language)) {
        AppLanguage.v1Cases.forEach { lang ->
            PickerRow(
                emoji = lang.flagEmoji,
                label = lang.displayName,
                selected = active == lang,
                onClick = {
                    vm.setLanguage(lang)
                    val locale = when (lang) {
                        AppLanguage.Turkish -> LocaleHelper.Language.Turkish
                        AppLanguage.German -> LocaleHelper.Language.German
                        AppLanguage.English -> LocaleHelper.Language.English
                    }
                    LocaleHelper.setLanguage(context, locale)
                    onDismiss()
                    // Cold-launch the app under the new locale. setApplicationLocales
                    // *does* trigger an Activity recreate on its own, but recreate
                    // keeps Hilt ViewModels alive — Compose state / cached flows
                    // can show the old language until the user navigates around.
                    // Restarting the process is the cleanest way to land everyone
                    // (notifications, splash, AppRoot, all VMs) in the new locale.
                    restartApp(context)
                },
            )
        }
        Spacer(Modifier.height(Spacing.sm))
        Text(
            text = stringResource(R.string.language_footer),
            style = BrandText.footnote,
            color = BrandColor.textTertiary(),
            modifier = Modifier.padding(horizontal = Spacing.md, vertical = Spacing.sm),
        )
    }
}

/**
 * Re-create the host Activity so Compose pulls the new locale from the
 * refreshed Configuration. With `android:configChanges` no longer absorbing
 * the locale change (removed from the manifest) AppCompatDelegate will also
 * trigger this automatically on Android 13+, but we call it ourselves for
 * older OS versions / OEMs that swallow the auto-recreate.
 *
 * No process kill: AlarmManager-scheduled restarts are unreliable on
 * Oppo/MIUI background restrictions and tend to land the user on a black
 * launcher icon instead of the app.
 */
private fun restartApp(context: android.content.Context) {
    var ctx: android.content.Context? = context
    while (ctx is android.content.ContextWrapper && ctx !is android.app.Activity) {
        ctx = ctx.baseContext
    }
    (ctx as? android.app.Activity)?.recreate()
}

@Composable
fun CurrencyPickerSheet(onDismiss: () -> Unit) {
    val vm: SettingsViewModel = hiltViewModel()
    val state by vm.state.collectAsStateWithLifecycle()
    val active = state.currency

    PickerColumn(title = stringResource(R.string.settings_currency)) {
        listOf(
            AppCurrency.Try to R.string.currency_try,
            AppCurrency.Usd to R.string.currency_usd,
            AppCurrency.Eur to R.string.currency_eur,
            AppCurrency.Gbp to R.string.currency_gbp,
        ).forEach { (currency, labelRes) ->
            PickerRow(
                symbol = currency.symbol,
                label = "${stringResource(labelRes)} · ${currency.raw}",
                selected = active == currency,
                onClick = { vm.setCurrency(currency); onDismiss() },
            )
        }
    }
}

// ── Building blocks ────────────────────────────────────────────────────────

@Composable
private fun PickerColumn(title: String, content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(BrandColor.background())
            .padding(horizontal = Spacing.lg, vertical = Spacing.md),
        verticalArrangement = Arrangement.spacedBy(Spacing.sm),
    ) {
        Text(
            text = title,
            style = BrandText.title,
            color = BrandColor.textPrimary(),
            modifier = Modifier.padding(bottom = Spacing.xs),
        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Spacing.radiusMedium))
                .background(BrandColor.surface().copy(alpha = 0.4f))
                .padding(vertical = Spacing.xs),
        ) {
            content()
        }
        Spacer(Modifier.height(Spacing.lg))
    }
}

@Composable
private fun PickerRow(
    icon: ImageVector? = null,
    emoji: String? = null,
    symbol: String? = null,
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = Spacing.md, horizontal = Spacing.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(30.dp)
                .clip(CircleShape)
                .background(BrandColor.Primary.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center,
        ) {
            when {
                icon != null -> Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = BrandColor.Primary,
                    modifier = Modifier.size(18.dp),
                )
                emoji != null -> Text(
                    text = emoji,
                    style = BrandText.subheadline,
                )
                symbol != null -> Text(
                    text = symbol,
                    style = BrandText.subheadline,
                    color = BrandColor.Primary,
                )
            }
        }
        Spacer(Modifier.width(Spacing.md))
        Text(
            text = label,
            style = BrandText.body,
            color = BrandColor.textPrimary(),
            modifier = Modifier.weight(1f),
        )
        if (selected) {
            Icon(
                imageVector = Icons.Filled.Check,
                contentDescription = stringResource(R.string.theme_active),
                tint = BrandColor.Primary,
                modifier = Modifier.size(20.dp),
            )
        }
    }
}
