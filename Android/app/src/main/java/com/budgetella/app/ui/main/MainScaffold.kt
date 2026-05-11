package com.budgetella.app.ui.main

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
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
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.Spacing
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.ui.budgi.BudgiScreen
import com.budgetella.app.ui.dashboard.DashboardScreen
import com.budgetella.app.ui.notifications.NotificationInboxScreen
import com.budgetella.app.ui.settings.CurrencyPickerSheet
import com.budgetella.app.ui.settings.LanguagePickerSheet
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
                )
                AppTab.List -> TransactionsScreen(onEdit = { sheetTrigger = AddEditTrigger.Edit(it) })
                AppTab.Stats -> StatsScreen()
                AppTab.Ai -> BudgiScreen()
            }
        }

        // Gear icon overlay — top-right, sits above the pager.
        IconButton(
            onClick = { showSettings = true },
            modifier = Modifier
                .align(Alignment.TopEnd)
                .statusBarsPadding()
                .padding(Spacing.sm),
        ) {
            Icon(
                imageVector = Icons.Filled.Settings,
                contentDescription = "Settings",
                tint = BrandColor.textSecondary(),
            )
        }

        BottomTabBar(
            tabs = tabs,
            selected = selectedTab,
            onSelect = { tab -> scope.launch { pagerState.animateScrollToPage(tab.ordinal) } },
            onFabClick = { sheetTrigger = AddEditTrigger.Add },
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
                }
            }
        }
    }
}

private sealed interface AddEditTrigger {
    data object Add : AddEditTrigger
    data class Edit(val transaction: TransactionEntity) : AddEditTrigger
}

private enum class SecondarySheet { Theme, Language, Currency, Inbox }
