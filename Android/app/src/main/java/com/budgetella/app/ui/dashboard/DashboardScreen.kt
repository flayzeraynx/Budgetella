package com.budgetella.app.ui.dashboard

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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
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
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.model.Money
import com.budgetella.app.ui.budgi.BudgiInsight
import com.budgetella.app.ui.transactions.TransactionRow
import com.patrykandpatrick.vico.compose.cartesian.CartesianChartHost
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberLineCartesianLayer
import com.patrykandpatrick.vico.compose.cartesian.rememberCartesianChart
import com.patrykandpatrick.vico.compose.cartesian.rememberVicoZoomState
import com.patrykandpatrick.vico.core.cartesian.data.CartesianChartModelProducer
import com.patrykandpatrick.vico.core.cartesian.data.lineSeries
import com.patrykandpatrick.vico.core.cartesian.layer.LineCartesianLayer
import java.time.format.TextStyle
import java.util.Locale

/**
 * Home / Dashboard — port of iOS DashboardView.
 *
 * Three cards in a vertical scroll: balance hero, daily-flow line chart, and
 * recent transactions. Top-categories slot in between the chart and the
 * recent list. Tapping any recent row opens the edit sheet (the lambda is
 * threaded from MainScaffold).
 */
@Composable
fun DashboardScreen(
    onEditTransaction: (TransactionEntity) -> Unit,
    onOpenBudgi: () -> Unit = {},
    modifier: Modifier = Modifier,
) {
    val vm: DashboardViewModel = hiltViewModel()
    val state by vm.state.collectAsStateWithLifecycle()

    if (!state.hasAnyTransactions) {
        EmptyDashboard(modifier)
        return
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BrandColor.background())
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(bottom = 120.dp),
    ) {
        // Title header
        Text(
            text = stringResource(R.string.dashboard_title),
            style = BrandText.largeTitle,
            color = BrandColor.textPrimary(),
            modifier = Modifier.padding(horizontal = Spacing.xl, vertical = Spacing.lg),
        )

        BalanceHero(state = state)
        Spacer(Modifier.height(Spacing.lg))

        if (state.dailyFlow.any { it.incomeMinor + it.expenseMinor > 0 }) {
            FlowChartCard(state = state)
            Spacer(Modifier.height(Spacing.lg))
        }

        state.featuredInsight?.let { insight ->
            AIInsightCard(insight = insight, onTap = onOpenBudgi)
            Spacer(Modifier.height(Spacing.lg))
        }

        if (state.topCategories.isNotEmpty()) {
            TopCategoriesCard(state = state)
            Spacer(Modifier.height(Spacing.lg))
        }

        RecentTransactionsCard(state = state, onEdit = onEditTransaction)
    }
}

// ── Balance hero ───────────────────────────────────────────────────────────

@Composable
private fun BalanceHero(state: DashboardState) {
    val net = Money(state.netMinor).toBigDecimal()
    val income = Money(state.incomeMinor).toBigDecimal()
    val expense = Money(state.expenseMinor).toBigDecimal()
    val netColor = if (state.netMinor >= 0) BrandColor.Income else BrandColor.Expense

    Column(
        modifier = Modifier
            .padding(horizontal = Spacing.xl)
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusLarge))
            .background(
                Brush.linearGradient(
                    listOf(
                        BrandColor.Primary.copy(alpha = 0.25f),
                        BrandColor.PrimaryLight.copy(alpha = 0.10f),
                    )
                )
            )
            .padding(Spacing.xl),
    ) {
        Text(
            text = stringResource(R.string.dashboard_net_label) + " · " +
                state.month.month.getDisplayName(TextStyle.FULL, Locale.getDefault()),
            style = BrandText.caption,
            color = BrandColor.textTertiary(),
        )
        Spacer(Modifier.height(Spacing.xs))
        Text(
            text = "₺" + "%,.2f".format(net),
            style = BrandText.displayHero,
            color = netColor,
        )

        Spacer(Modifier.height(Spacing.lg))
        Row(modifier = Modifier.fillMaxWidth()) {
            MoneyBlock(
                label = stringResource(R.string.dashboard_income_label),
                amount = income,
                accent = BrandColor.Income,
                modifier = Modifier.weight(1f),
            )
            Spacer(Modifier.width(Spacing.md))
            MoneyBlock(
                label = stringResource(R.string.dashboard_expense_label),
                amount = expense,
                accent = BrandColor.Expense,
                modifier = Modifier.weight(1f),
            )
        }
    }
}

@Composable
private fun MoneyBlock(
    label: String,
    amount: java.math.BigDecimal,
    accent: Color,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .height(8.dp)
                    .width(8.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(accent),
            )
            Spacer(Modifier.width(6.dp))
            Text(text = label, style = BrandText.caption, color = BrandColor.textTertiary())
        }
        Spacer(Modifier.height(4.dp))
        Text(
            text = "₺" + "%,.2f".format(amount),
            style = BrandText.subheadline,
            color = BrandColor.textPrimary(),
        )
    }
}

// ── Daily flow line chart (Vico) ───────────────────────────────────────────

@Composable
private fun FlowChartCard(state: DashboardState) {
    val producer = remember { CartesianChartModelProducer() }
    val incomeData = state.dailyFlow.map { it.incomeMinor / 100.0 }   // major-units for axis readability
    val expenseData = state.dailyFlow.map { it.expenseMinor / 100.0 }

    androidx.compose.runtime.LaunchedEffect(state.dailyFlow) {
        producer.runTransaction {
            lineSeries {
                series(incomeData)
                series(expenseData)
            }
        }
    }

    Column(
        modifier = Modifier
            .padding(horizontal = Spacing.xl)
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(BrandColor.surface().copy(alpha = 0.6f))
            .padding(Spacing.lg),
    ) {
        Text(
            text = stringResource(R.string.dashboard_flow_title),
            style = BrandText.caption2,
            color = BrandColor.textTertiary(),
        )
        Spacer(Modifier.height(Spacing.md))

        CartesianChartHost(
            chart = rememberCartesianChart(
                rememberLineCartesianLayer(
                    lineProvider = LineCartesianLayer.LineProvider.series(
                        LineCartesianLayer.rememberLine(
                            fill = LineCartesianLayer.LineFill.single(
                                fill = com.patrykandpatrick.vico.core.common.Fill(BrandColor.Income.toArgb())
                            ),
                        ),
                        LineCartesianLayer.rememberLine(
                            fill = LineCartesianLayer.LineFill.single(
                                fill = com.patrykandpatrick.vico.core.common.Fill(BrandColor.Expense.toArgb())
                            ),
                        ),
                    ),
                ),
            ),
            modelProducer = producer,
            modifier = Modifier
                .fillMaxWidth()
                .height(140.dp),
            zoomState = rememberVicoZoomState(zoomEnabled = false),
        )
    }
}

// ── Top categories ─────────────────────────────────────────────────────────

@Composable
private fun TopCategoriesCard(state: DashboardState) {
    Column(
        modifier = Modifier
            .padding(horizontal = Spacing.xl)
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(BrandColor.surface().copy(alpha = 0.6f))
            .padding(Spacing.lg),
        verticalArrangement = Arrangement.spacedBy(Spacing.md),
    ) {
        Text(
            text = stringResource(R.string.dashboard_top_categories_title),
            style = BrandText.caption2,
            color = BrandColor.textTertiary(),
        )
        state.topCategories.forEach { stat ->
            val tint = runCatching { Color(android.graphics.Color.parseColor(stat.category.colorHex)) }
                .getOrDefault(BrandColor.Primary)
            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .height(10.dp)
                            .width(10.dp)
                            .clip(RoundedCornerShape(50))
                            .background(tint),
                    )
                    Spacer(Modifier.width(Spacing.sm))
                    Text(
                        text = stat.category.name,
                        style = BrandText.subheadline,
                        color = BrandColor.textPrimary(),
                        modifier = Modifier.weight(1f),
                    )
                    Text(
                        text = "₺" + "%,.0f".format(Money(stat.amountMinor).toBigDecimal()),
                        style = BrandText.subheadline,
                        color = BrandColor.textSecondary(),
                    )
                }
                Spacer(Modifier.height(6.dp))
                ProgressBar(progress = stat.percentageOfExpense, color = tint)
            }
        }
    }
}

@Composable
private fun ProgressBar(progress: Float, color: Color) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(4.dp)
            .clip(RoundedCornerShape(50))
            .background(BrandColor.borderSubtle()),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(progress.coerceIn(0f, 1f))
                .height(4.dp)
                .clip(RoundedCornerShape(50))
                .background(color),
        )
    }
}

// ── Recent transactions ────────────────────────────────────────────────────

@Composable
private fun RecentTransactionsCard(
    state: DashboardState,
    onEdit: (TransactionEntity) -> Unit,
) {
    Column(modifier = Modifier.padding(horizontal = Spacing.xl)) {
        Text(
            text = stringResource(R.string.dashboard_recent_title),
            style = BrandText.caption2,
            color = BrandColor.textTertiary(),
            modifier = Modifier.padding(start = Spacing.xs, bottom = Spacing.sm),
        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Spacing.radiusMedium))
                .background(BrandColor.surface().copy(alpha = 0.6f)),
        ) {
            state.recentTransactions.forEachIndexed { index, tx ->
                TransactionRow(
                    transaction = tx,
                    category = tx.categoryId?.let { state.recentCategoriesById[it] },
                    onClick = { onEdit(tx) },
                    onLongClick = { /* delete from list only — keep dashboard taps simple */ },
                )
                if (index < state.recentTransactions.lastIndex) {
                    HorizontalDivider(
                        color = BrandColor.borderSubtle(),
                        modifier = Modifier.padding(start = 68.dp),
                    )
                }
            }
        }
    }
}

// ── AI insight card ────────────────────────────────────────────────────────

@Composable
private fun AIInsightCard(insight: BudgiInsight, onTap: () -> Unit) {
    Row(
        modifier = Modifier
            .padding(horizontal = Spacing.xl)
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(BrandColor.surface().copy(alpha = 0.6f))
            .clickable(onClick = onTap)
            .padding(Spacing.lg),
    ) {
        Box(
            modifier = Modifier
                .width(3.dp)
                .height(40.dp)
                .background(insight.color()),
        )
        Spacer(Modifier.width(Spacing.md))
        Column(modifier = Modifier.weight(1f)) {
            Row {
                Text(
                    text = "BUDGI · AI",
                    style = BrandText.caption2,
                    color = BrandColor.Primary,
                    modifier = Modifier.weight(1f),
                )
                Text(
                    text = insight.tag,
                    style = BrandText.caption2,
                    color = androidx.compose.ui.graphics.Color.White,
                    modifier = Modifier
                        .clip(RoundedCornerShape(50))
                        .background(insight.color())
                        .padding(horizontal = 6.dp, vertical = 2.dp),
                )
            }
            Spacer(Modifier.height(4.dp))
            Text(
                text = insight.text,
                style = BrandText.footnote,
                color = BrandColor.textSecondary(),
                maxLines = 3,
            )
        }
    }
}

// ── Empty state ────────────────────────────────────────────────────────────

@Composable
private fun EmptyDashboard(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(BrandColor.background())
            .padding(horizontal = Spacing.xxl),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = stringResource(R.string.dashboard_empty_title),
                style = BrandText.title,
                color = BrandColor.textPrimary(),
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(Spacing.sm))
            Text(
                text = stringResource(R.string.dashboard_empty_body),
                style = BrandText.body,
                color = BrandColor.textTertiary(),
                textAlign = TextAlign.Center,
            )
        }
    }
}

