package com.budgetella.app.ui.main

import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.EditNote
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.ui.budgi.BudgiScreen
import com.budgetella.app.ui.dashboard.DashboardScreen
import com.budgetella.app.ui.notifications.NotificationInboxScreen
import com.budgetella.app.ui.settings.CategoryManagementSheet
import com.budgetella.app.ui.settings.CurrencyPickerSheet
import com.budgetella.app.ui.settings.DeleteAccountSheet
import com.budgetella.app.ui.settings.LanguagePickerSheet
import com.budgetella.app.ui.settings.NotificationSettingsSheet
import com.budgetella.app.ui.settings.ProfileSheet
import com.budgetella.app.ui.settings.SettingsScreen
import com.budgetella.app.ui.settings.ThemePickerSheet
import com.budgetella.app.ui.stats.StatsScreen
import com.budgetella.app.ui.transactions.AddEditTransactionSheet
import com.budgetella.app.ui.transactions.TransactionsScreen
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Main shell — bottom tab bar + HorizontalPager. Also hosts every modal sheet
 * (add/edit transaction, settings, picker sheets, notification inbox) so the
 * sheets can survive tab swipes and never get stacked.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScaffold(
    onExportBackup: () -> Unit = {},
    onImportBackup: () -> Unit = {},
) {
    val tabs = remember { AppTab.ordered }
    val pagerState = rememberPagerState(
        initialPage = AppTab.Home.ordinal,
        pageCount = { tabs.size },
    )
    val scope = rememberCoroutineScope()

    val selectedTabIndex by remember(pagerState) {
        snapshotFlow { pagerState.targetPage }
    }.collectAsStateWithLifecycle(initialValue = pagerState.currentPage)
    val selectedTab = tabs[selectedTabIndex]

    // null = sheet hidden; AddEditTrigger.Add = blank add; AddEditTrigger.Edit(tx) = edit mode.
    var sheetTrigger by remember { mutableStateOf<AddEditTrigger?>(null) }

    // Settings + picker sheets. Only one is non-null at a time — we dismiss
    // Settings first, wait for the animation, then open the requested sibling.
    var showSettings by remember { mutableStateOf(false) }
    var pendingSecondary by remember { mutableStateOf<SecondarySheet?>(null) }

    // FAB blob menu — tap the (+) to expand into a 3-option row above the bar.
    var fabMenuVisible by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val comingSoonMsg = stringResource(R.string.entry_mode_coming_soon)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BrandColor.background())
    ) {
        HorizontalPager(
            state = pagerState,
            modifier = Modifier
                .fillMaxSize()
                .padding(bottom = 72.dp),
            beyondViewportPageCount = 1,
            key = { tabs[it].name },
        ) { page ->
            when (tabs[page]) {
                AppTab.Home -> DashboardScreen(
                    onEditTransaction = { sheetTrigger = AddEditTrigger.Edit(it) },
                    onOpenBudgi = { scope.launch { pagerState.animateScrollToPage(AppTab.Ai.ordinal) } },
                    onShowSettings = { showSettings = true },
                )
                AppTab.List -> TransactionsScreen(onEdit = { sheetTrigger = AddEditTrigger.Edit(it) })
                AppTab.Stats -> StatsScreen()
                AppTab.Ai -> BudgiScreen()
            }
        }

        // Settings is opened from the Dashboard avatar (Home tab) — no
        // floating gear icon needed any more.

        // Scrim swallows taps when the FAB menu is open — tap anywhere outside
        // the blob to close. Rendered before the tab bar so the bar stays on top.
        AnimatedVisibility(
            visible = fabMenuVisible,
            enter = fadeIn(),
            exit = fadeOut(),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.35f))
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                    ) { fabMenuVisible = false },
            )
        }

        // FAB blob — 3 entry-mode pills (voice / manual / camera). Sits just
        // above the tab bar so the (+) button stays anchored as a "dismiss"
        // target underneath the menu.
        AnimatedVisibility(
            visible = fabMenuVisible,
            enter = fadeIn() + scaleIn(initialScale = 0.7f, animationSpec = spring()),
            exit = fadeOut() + scaleOut(targetScale = 0.7f, animationSpec = spring()),
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding()
                .padding(bottom = 96.dp),
        ) {
            FabBlobMenu(
                onPickManual = {
                    fabMenuVisible = false
                    sheetTrigger = AddEditTrigger.Add
                },
                onPickVoice = {
                    fabMenuVisible = false
                    Toast.makeText(context, comingSoonMsg, Toast.LENGTH_SHORT).show()
                },
                onPickCamera = {
                    fabMenuVisible = false
                    Toast.makeText(context, comingSoonMsg, Toast.LENGTH_SHORT).show()
                },
            )
        }

        BottomTabBar(
            tabs = tabs,
            selected = selectedTab,
            onSelect = { tab ->
                fabMenuVisible = false
                scope.launch { pagerState.animateScrollToPage(tab.ordinal) }
            },
            onFabClick = { fabMenuVisible = !fabMenuVisible },
            modifier = Modifier.align(Alignment.BottomCenter),
        )

        // Add/Edit sheet.
        sheetTrigger?.let { trigger ->
            AddEditTransactionSheet(
                existing = (trigger as? AddEditTrigger.Edit)?.transaction,
                onDismiss = { sheetTrigger = null },
            )
        }

        // Settings sheet (top-level).
        if (showSettings) {
            val settingsSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
            ModalBottomSheet(
                onDismissRequest = { showSettings = false },
                sheetState = settingsSheetState,
                containerColor = BrandColor.background(),
                dragHandle = null,
            ) {
                SettingsScreen(
                    onDismiss = { showSettings = false },
                    onShowTheme = {
                        showSettings = false
                        scope.launch {
                            delay(280)
                            pendingSecondary = SecondarySheet.Theme
                        }
                    },
                    onShowLanguage = {
                        showSettings = false
                        scope.launch {
                            delay(280)
                            pendingSecondary = SecondarySheet.Language
                        }
                    },
                    onShowCurrency = {
                        showSettings = false
                        scope.launch {
                            delay(280)
                            pendingSecondary = SecondarySheet.Currency
                        }
                    },
                    onExport = onExportBackup,
                    onImport = onImportBackup,
                    onShowInbox = {
                        showSettings = false
                        scope.launch {
                            delay(280)
                            pendingSecondary = SecondarySheet.Inbox
                        }
                    },
                    onShowProfile = {
                        showSettings = false
                        scope.launch {
                            delay(280)
                            pendingSecondary = SecondarySheet.Profile
                        }
                    },
                    onDeleteAccount = {
                        showSettings = false
                        scope.launch {
                            delay(280)
                            pendingSecondary = SecondarySheet.DeleteAccount
                        }
                    },
                    onShowNotificationSettings = {
                        showSettings = false
                        scope.launch {
                            delay(280)
                            pendingSecondary = SecondarySheet.NotificationSettings
                        }
                    },
                    onShowCategories = {
                        showSettings = false
                        scope.launch {
                            delay(280)
                            pendingSecondary = SecondarySheet.Categories
                        }
                    },
                )
            }
        }

        // Secondary sheets — one at a time.
        pendingSecondary?.let { sheet ->
            val state = rememberModalBottomSheetState(skipPartiallyExpanded = true)
            ModalBottomSheet(
                onDismissRequest = { pendingSecondary = null },
                sheetState = state,
                containerColor = BrandColor.background(),
                dragHandle = null,
            ) {
                when (sheet) {
                    SecondarySheet.Theme -> ThemePickerSheet(onDismiss = { pendingSecondary = null })
                    SecondarySheet.Language -> LanguagePickerSheet(onDismiss = { pendingSecondary = null })
                    SecondarySheet.Currency -> CurrencyPickerSheet(onDismiss = { pendingSecondary = null })
                    SecondarySheet.Inbox -> NotificationInboxScreen(onDismiss = { pendingSecondary = null })
                    SecondarySheet.Profile -> ProfileSheet(onDismiss = { pendingSecondary = null })
                    SecondarySheet.DeleteAccount -> DeleteAccountSheet(onDismiss = { pendingSecondary = null })
                    SecondarySheet.NotificationSettings ->
                        NotificationSettingsSheet(onDismiss = { pendingSecondary = null })
                    SecondarySheet.Categories ->
                        CategoryManagementSheet(onDismiss = { pendingSecondary = null })
                }
            }
        }
    }
}

private sealed interface AddEditTrigger {
    data object Add : AddEditTrigger
    data class Edit(val transaction: TransactionEntity) : AddEditTrigger
}

private enum class SecondarySheet {
    Theme, Language, Currency, Inbox, Profile, DeleteAccount,
    NotificationSettings, Categories
}

/**
 * Blob menu shown above the (+) FAB. Mirrors iOS CustomTabBar's blob — the
 * iOS version uses long-press + drag, but on Android we use plain taps:
 * tap FAB to expand, tap an option to commit. Voice and Camera are wired to
 * "coming soon" toasts until ML Kit (camera/receipt OCR) and Speech-to-Text
 * are integrated post-v1.
 */
@Composable
private fun FabBlobMenu(
    onPickManual: () -> Unit,
    onPickVoice: () -> Unit,
    onPickCamera: () -> Unit,
) {
    Row(
        modifier = Modifier
            .shadow(elevation = 16.dp, shape = RoundedCornerShape(24.dp))
            .clip(RoundedCornerShape(24.dp))
            .background(BrandColor.surface()),
        horizontalArrangement = Arrangement.spacedBy(2.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        BlobOption(
            icon = androidx.compose.material.icons.Icons.Filled.Mic,
            label = stringResource(R.string.entry_mode_voice),
            onClick = onPickVoice,
        )
        BlobOption(
            icon = androidx.compose.material.icons.Icons.Filled.EditNote,
            label = stringResource(R.string.entry_mode_manual),
            onClick = onPickManual,
            primary = true,
        )
        BlobOption(
            icon = androidx.compose.material.icons.Icons.Filled.CameraAlt,
            label = stringResource(R.string.entry_mode_camera),
            onClick = onPickCamera,
        )
    }
}

@Composable
private fun BlobOption(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    primary: Boolean = false,
) {
    Column(
        modifier = Modifier
            .clip(RoundedCornerShape(20.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.md, vertical = Spacing.sm),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .size(width = 52.dp, height = 44.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(if (primary) BrandColor.Primary else Color.Transparent),
            contentAlignment = Alignment.Center,
        ) {
            androidx.compose.material3.Icon(
                imageVector = icon,
                contentDescription = label,
                tint = if (primary) Color.White else BrandColor.textSecondary(),
                modifier = Modifier.size(22.dp),
            )
        }
        Spacer(Modifier.height(4.dp))
        androidx.compose.material3.Text(
            text = label,
            style = BrandText.caption,
            color = if (primary) BrandColor.Primary else BrandColor.textTertiary(),
        )
    }
}
