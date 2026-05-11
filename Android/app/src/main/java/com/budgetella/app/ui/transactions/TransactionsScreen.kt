package com.budgetella.app.ui.transactions

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.model.TransactionType
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale

/**
 * Transactions list — port of iOS TransactionsView. Lazy year/month/day
 * sections, long-press to delete, tap to edit (edit sheet wiring is part of
 * the FAB task that bundles add + edit together).
 */
@Composable
fun TransactionsScreen(
    onEdit: (TransactionEntity) -> Unit,
    modifier: Modifier = Modifier,
) {
    val vm: TransactionsViewModel = hiltViewModel()
    val groups by vm.groupedTransactions.collectAsStateWithLifecycle()
    val categories by vm.categories.collectAsStateWithLifecycle()
    val ui by vm.ui.collectAsStateWithLifecycle()
    val hasAny by vm.hasAnyTransactions.collectAsStateWithLifecycle()
    val isEmpty by vm.isEmpty.collectAsStateWithLifecycle()

    val categoryById = remember(categories) { categories.associateBy { it.id } }

    var pendingDelete by remember { mutableStateOf<TransactionEntity?>(null) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BrandColor.background())
            .statusBarsPadding()
    ) {
        TopBar(
            typeFilter = ui.typeFilter,
            onTypeFilterChange = vm::setTypeFilter,
        )
        HorizontalDivider(color = BrandColor.borderSubtle())

        if (isEmpty) {
            EmptyState(filtered = hasAny)
        } else {
            LazyColumn(
                contentPadding = PaddingValues(bottom = 120.dp, top = Spacing.sm),
            ) {
                groups.forEach { yearGroup ->
                    item(key = "year-${yearGroup.year}") {
                        Text(
                            text = yearGroup.year.toString(),
                            style = BrandText.title,
                            color = BrandColor.textPrimary(),
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = Spacing.xl, vertical = Spacing.md),
                        )
                    }

                    yearGroup.months.forEach { monthGroup ->
                        item(key = "month-${monthGroup.year}-${monthGroup.month}") {
                            Text(
                                text = monthName(monthGroup.month),
                                style = BrandText.headline,
                                color = BrandColor.Primary,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = Spacing.xl, top = Spacing.md, bottom = Spacing.xs),
                            )
                        }

                        monthGroup.days.forEach { dayGroup ->
                            item(key = "day-${dayGroup.date}") {
                                Text(
                                    text = dayHeader(dayGroup),
                                    style = BrandText.caption,
                                    color = BrandColor.textTertiary(),
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(horizontal = Spacing.xl, top = Spacing.sm, bottom = 4.dp),
                                )
                            }

                            item(key = "card-${dayGroup.date}") {
                                Column(
                                    modifier = Modifier
                                        .padding(horizontal = Spacing.xl, vertical = Spacing.xs)
                                        .clip(RoundedCornerShape(Spacing.radiusMedium))
                                        .background(BrandColor.surface().copy(alpha = 0.6f))
                                ) {
                                    dayGroup.transactions.forEachIndexed { index, tx ->
                                        TransactionRow(
                                            transaction = tx,
                                            category = tx.categoryId?.let { categoryById[it] },
                                            onClick = { onEdit(tx) },
                                            onLongClick = { pendingDelete = tx },
                                        )
                                        if (index < dayGroup.transactions.lastIndex) {
                                            HorizontalDivider(
                                                color = BrandColor.borderSubtle(),
                                                modifier = Modifier.padding(start = 68.dp)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    pendingDelete?.let { tx ->
        AlertDialog(
            onDismissRequest = { pendingDelete = null },
            title = { Text(stringResource(R.string.transactions_delete_title)) },
            text = {
                Text(
                    text = tx.note.ifBlank { stringResource(R.string.transactions_unnamed) },
                    color = BrandColor.textSecondary(),
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    vm.delete(tx)
                    pendingDelete = null
                }) { Text(stringResource(R.string.common_delete), color = BrandColor.Expense) }
            },
            dismissButton = {
                TextButton(onClick = { pendingDelete = null }) {
                    Text(stringResource(R.string.common_cancel))
                }
            },
        )
    }
}

// ── Top bar (type filter pill) ─────────────────────────────────────────────

@Composable
private fun TopBar(
    typeFilter: TransactionType?,
    onTypeFilterChange: (TransactionType?) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.xl, vertical = Spacing.sm),
        horizontalArrangement = Arrangement.Center,
    ) {
        Row(
            modifier = Modifier
                .clip(CircleShape)
                .background(BrandColor.surface().copy(alpha = 0.5f))
                .padding(3.dp),
        ) {
            FilterPill(
                label = stringResource(R.string.transactions_filter_all),
                selected = typeFilter == null,
                accent = BrandColor.Primary,
                onClick = { onTypeFilterChange(null) },
            )
            FilterPill(
                label = stringResource(R.string.transactions_filter_income),
                selected = typeFilter == TransactionType.Income,
                accent = BrandColor.Income,
                onClick = { onTypeFilterChange(TransactionType.Income) },
            )
            FilterPill(
                label = stringResource(R.string.transactions_filter_expense),
                selected = typeFilter == TransactionType.Expense,
                accent = BrandColor.Expense,
                onClick = { onTypeFilterChange(TransactionType.Expense) },
            )
        }
    }
}

@Composable
private fun FilterPill(
    label: String,
    selected: Boolean,
    accent: androidx.compose.ui.graphics.Color,
    onClick: () -> Unit,
) {
    Box(
        modifier = Modifier
            .clip(CircleShape)
            .background(if (selected) accent else androidx.compose.ui.graphics.Color.Transparent)
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.md, vertical = 5.dp),
    ) {
        Text(
            text = label,
            style = BrandText.footnote,
            color = if (selected) androidx.compose.ui.graphics.Color.White else BrandColor.textSecondary(),
        )
    }
}

// ── Empty state ─────────────────────────────────────────────────────────────

@Composable
private fun EmptyState(filtered: Boolean) {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.md),
            modifier = Modifier.padding(horizontal = Spacing.xxl),
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.List,
                contentDescription = null,
                tint = BrandColor.Primary,
                modifier = Modifier.size(48.dp),
            )
            Text(
                text = stringResource(
                    if (filtered) R.string.transactions_empty_filtered_title
                    else R.string.transactions_empty_title
                ),
                style = BrandText.title,
                color = BrandColor.textPrimary(),
                textAlign = TextAlign.Center,
            )
            Text(
                text = stringResource(
                    if (filtered) R.string.transactions_empty_filtered_body
                    else R.string.transactions_empty_body
                ),
                style = BrandText.body,
                color = BrandColor.textTertiary(),
                textAlign = TextAlign.Center,
            )
        }
    }
}

// ── Header helpers ─────────────────────────────────────────────────────────

private fun monthName(month: Int): String =
    java.time.Month.of(month).getDisplayName(TextStyle.FULL, Locale.getDefault())

private fun dayHeader(dayGroup: TransactionDayGroup): String {
    val date = dayGroup.date
    val today = java.time.LocalDate.now()
    return when {
        date == today -> "TODAY"
        date == today.minusDays(1) -> "YESTERDAY"
        else -> date.format(DateTimeFormatter.ofPattern("EEE d MMM", Locale.getDefault())).uppercase(Locale.getDefault())
    }
}
