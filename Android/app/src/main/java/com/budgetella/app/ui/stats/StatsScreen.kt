package com.budgetella.app.ui.stats

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import com.budgetella.app.data.model.Money
import com.budgetella.app.data.model.TransactionType

/**
 * Stats — port of iOS StatsView.
 *
 * Income/Expense toggle, hand-drawn donut (Vico doesn't ship a pie/donut in
 * 2.0-beta yet), big total + month-over-month delta pill, category list with
 * progress bars. Period header reads the current month from the ViewModel.
 */
@Composable
fun StatsScreen(modifier: Modifier = Modifier) {
    val vm: StatsViewModel = hiltViewModel()
    val state by vm.state.collectAsStateWithLifecycle()

    // Refire the Budgi insight compute when the locale changes — mirrors the
    // hook the Dashboard uses so the rule output swaps language without a
    // process restart.
    val currentLangTag = LocalContext.current.resources.configuration.locales
        .toLanguageTags()
        .substringBefore(',')
    LaunchedEffect(currentLangTag) { vm.refreshLocale() }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BrandColor.background())
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(bottom = 120.dp),
    ) {
        // Title + month picker row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.xl, vertical = Spacing.lg),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = stringResource(R.string.stats_title),
                style = BrandText.largeTitle,
                color = BrandColor.textPrimary(),
                modifier = Modifier.weight(1f),
            )
            StatsMonthPicker(
                current = state.month,
                items = state.availableMonths,
                onSelect = vm::selectMonth,
            )
        }

        // Income/Expense toggle
        TypeToggle(state.ui.showingType, vm::toggleType)

        Spacer(Modifier.height(Spacing.lg))

        if (state.totalMinor == 0L && state.breakdown.isEmpty()) {
            EmptyStats()
            return@Column
        }

        DonutWithTotal(state)
        Spacer(Modifier.height(Spacing.xl))

        // Budgi rule insight — same surface as Dashboard's AIInsightCard.
        state.featuredInsight?.let { insight ->
            com.budgetella.app.ui.dashboard.AIInsightCard(
                insight = insight,
                onTap = {},
            )
            Spacer(Modifier.height(Spacing.lg))
        }

        if (state.breakdown.isNotEmpty()) {
            BreakdownList(state)
        }
    }
}

@Composable
private fun StatsMonthPicker(
    current: java.time.YearMonth,
    items: List<java.time.YearMonth>,
    onSelect: (java.time.YearMonth) -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }
    val format = remember {
        java.time.format.DateTimeFormatter.ofPattern("MMMM yyyy")
    }
    Box {
        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(Spacing.radiusFull))
                .background(BrandColor.background3())
                .clickable(enabled = items.isNotEmpty()) { expanded = true }
                .padding(horizontal = Spacing.md, vertical = Spacing.xs),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = current.format(format)
                    .replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() },
                style = BrandText.footnote,
                color = BrandColor.textPrimary(),
            )
            Spacer(Modifier.width(4.dp))
            Icon(
                imageVector = Icons.Filled.KeyboardArrowDown,
                contentDescription = null,
                tint = BrandColor.textTertiary(),
                modifier = Modifier.size(16.dp),
            )
        }
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            modifier = Modifier.background(BrandColor.surface()),
        ) {
            items.forEach { ym ->
                DropdownMenuItem(
                    text = {
                        Text(
                            text = ym.format(format)
                                .replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() },
                            style = BrandText.body,
                            color = BrandColor.textPrimary(),
                        )
                    },
                    onClick = {
                        expanded = false
                        onSelect(ym)
                    },
                )
            }
        }
    }
}

// ── Toggle ─────────────────────────────────────────────────────────────────

@Composable
private fun TypeToggle(
    showing: TransactionType,
    onChange: (TransactionType) -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Center,
    ) {
        Row(
            modifier = Modifier
                .clip(CircleShape)
                .background(BrandColor.surface().copy(alpha = 0.5f))
                .padding(3.dp),
        ) {
            Pill(
                label = stringResource(R.string.transactions_filter_expense),
                selected = showing == TransactionType.Expense,
                accent = BrandColor.Expense,
                onClick = { onChange(TransactionType.Expense) },
            )
            Pill(
                label = stringResource(R.string.transactions_filter_income),
                selected = showing == TransactionType.Income,
                accent = BrandColor.Income,
                onClick = { onChange(TransactionType.Income) },
            )
        }
    }
}

@Composable
private fun Pill(label: String, selected: Boolean, accent: Color, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .clip(CircleShape)
            .background(if (selected) accent else Color.Transparent)
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.lg, vertical = Spacing.sm),
    ) {
        Text(
            text = label,
            style = BrandText.subheadline,
            color = if (selected) Color.White else BrandColor.textSecondary(),
        )
    }
}

// ── Donut + total ──────────────────────────────────────────────────────────

@Composable
private fun DonutWithTotal(state: StatsState) {
    Row(
        modifier = Modifier
            .padding(horizontal = Spacing.xl)
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(BrandColor.surface().copy(alpha = 0.5f))
            .padding(Spacing.lg),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        DonutCanvas(
            breakdown = state.breakdown,
            modifier = Modifier.size(110.dp),
        )
        Spacer(Modifier.width(Spacing.lg))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = stringResource(
                    if (state.ui.showingType == TransactionType.Expense) R.string.stats_total_expense
                    else R.string.stats_total_income
                ),
                style = BrandText.caption2,
                color = BrandColor.textTertiary(),
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = com.budgetella.app.core.design.moneyText(state.totalMinor),
                style = BrandText.displayHero,
                color = if (state.ui.showingType == TransactionType.Income) BrandColor.Income else BrandColor.textPrimary(),
            )
            state.changeVsPrev?.let { pct ->
                Spacer(Modifier.height(6.dp))
                ChangePill(pct = pct, expenseGoodWhenDown = state.ui.showingType == TransactionType.Expense)
            }
        }
    }
}

@Composable
private fun ChangePill(pct: Float, expenseGoodWhenDown: Boolean) {
    val up = pct >= 0f
    // Up arrow + red when spending grew, green when income grew, etc.
    val color = if (expenseGoodWhenDown) {
        if (up) BrandColor.Expense else BrandColor.Income
    } else {
        if (up) BrandColor.Income else BrandColor.Expense
    }
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(
            imageVector = if (up) Icons.Filled.ArrowUpward else Icons.Filled.ArrowDownward,
            contentDescription = null,
            tint = color,
            modifier = Modifier.size(12.dp),
        )
        Spacer(Modifier.width(3.dp))
        Text(
            text = stringResource(R.string.stats_change_vs_last, kotlin.math.abs(pct)),
            style = BrandText.footnote,
            color = color,
        )
    }
}

@Composable
private fun DonutCanvas(breakdown: List<CategoryStat>, modifier: Modifier = Modifier) {
    val total = breakdown.sumOf { it.amountMinor.toDouble() }.takeIf { it > 0 } ?: 0.0
    // Composable colour lookups must happen outside the DrawScope lambda.
    val emptyRingColor = BrandColor.borderSubtle().copy(alpha = 0.6f)
    Canvas(modifier = modifier) {
        val strokeWidth = size.minDimension * 0.18f
        val diameter = size.minDimension - strokeWidth
        val topLeft = Offset(
            (size.width - diameter) / 2f,
            (size.height - diameter) / 2f,
        )
        val arcSize = Size(diameter, diameter)

        if (total <= 0.0) {
            // Empty donut: a single muted ring.
            drawArc(
                color = emptyRingColor,
                startAngle = -90f,
                sweepAngle = 360f,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = strokeWidth),
            )
            return@Canvas
        }

        var start = -90f
        breakdown.forEach { stat ->
            val sweep = (stat.amountMinor.toDouble() / total).toFloat() * 360f
            val argb = runCatching { android.graphics.Color.parseColor(stat.category.colorHex) }
                .getOrDefault(BrandColor.Primary.toArgb())
            drawArc(
                color = Color(argb),
                startAngle = start,
                sweepAngle = sweep - 2f,    // small gap between segments for clarity
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = strokeWidth),
            )
            start += sweep
        }
    }
}

// ── Breakdown list ─────────────────────────────────────────────────────────

@Composable
private fun BreakdownList(state: StatsState) {
    Column(
        modifier = Modifier
            .padding(horizontal = Spacing.xl)
            .fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(Spacing.sm),
    ) {
        Text(
            text = stringResource(R.string.stats_categories_title),
            style = BrandText.caption2,
            color = BrandColor.textTertiary(),
            modifier = Modifier.padding(start = Spacing.xs, bottom = Spacing.xs),
        )
        state.breakdown.forEach { stat ->
            val tint = runCatching { Color(android.graphics.Color.parseColor(stat.category.colorHex)) }
                .getOrDefault(BrandColor.Primary)
            CategoryRow(stat = stat, accent = tint)
        }
    }
}

@Composable
private fun CategoryRow(stat: CategoryStat, accent: Color) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusSmall))
            .background(BrandColor.surface().copy(alpha = 0.5f))
            .padding(horizontal = Spacing.md, vertical = Spacing.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .clip(CircleShape)
                .background(accent),
        )
        Spacer(Modifier.width(Spacing.sm))
        Text(
            text = com.budgetella.app.core.locale.displayCategoryName(stat.category),
            style = BrandText.subheadline,
            color = BrandColor.textPrimary(),
            modifier = Modifier.width(110.dp),
            maxLines = 1,
        )
        Box(modifier = Modifier.weight(1f).padding(horizontal = Spacing.sm)) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(4.dp)
                    .clip(RoundedCornerShape(50))
                    .background(BrandColor.borderSubtle()),
            )
            Box(
                modifier = Modifier
                    .fillMaxWidth(stat.percentage.coerceIn(0f, 1f))
                    .height(4.dp)
                    .clip(RoundedCornerShape(50))
                    .background(accent),
            )
        }
        Text(
            text = com.budgetella.app.core.design.moneyText(
                minorUnits = stat.amountMinor,
                decimals = 0,
            ),
            style = BrandText.footnote,
            color = BrandColor.textSecondary(),
            textAlign = TextAlign.End,
            modifier = Modifier.width(72.dp),
        )
    }
}

// ── Empty state ────────────────────────────────────────────────────────────

@Composable
private fun EmptyStats() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.xxl, vertical = Spacing.xxl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.md),
    ) {
        Text(
            text = stringResource(R.string.stats_empty_title),
            style = BrandText.title,
            color = BrandColor.textPrimary(),
            textAlign = TextAlign.Center,
        )
        Text(
            text = stringResource(R.string.stats_empty_body),
            style = BrandText.body,
            color = BrandColor.textTertiary(),
            textAlign = TextAlign.Center,
        )
    }
}
