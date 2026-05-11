package com.budgetella.app.ui.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalContext
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
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberColumnCartesianLayer
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberLine
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberLineCartesianLayer
import com.patrykandpatrick.vico.compose.cartesian.rememberCartesianChart
import com.patrykandpatrick.vico.compose.cartesian.rememberVicoZoomState
import com.patrykandpatrick.vico.core.cartesian.data.CartesianChartModelProducer
import com.patrykandpatrick.vico.core.cartesian.data.columnSeries
import com.patrykandpatrick.vico.core.cartesian.data.lineSeries
import com.patrykandpatrick.vico.core.cartesian.layer.ColumnCartesianLayer
import com.patrykandpatrick.vico.core.cartesian.layer.LineCartesianLayer
import com.patrykandpatrick.vico.core.common.Fill
import com.patrykandpatrick.vico.core.common.component.LineComponent
import com.patrykandpatrick.vico.core.common.shape.CorneredShape
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
    onShowSettings: () -> Unit = {},
    modifier: Modifier = Modifier,
) {
    val vm: DashboardViewModel = hiltViewModel()
    val state by vm.state.collectAsStateWithLifecycle()

    // The AI insight string is locale-sensitive but cached by DashboardViewModel
    // — re-fire compute whenever the Configuration's language changes so the
    // Budgi card swaps language without a full process restart.
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
        // Greeting + avatar — always rendered, even on the empty state, so
        // first-launch lands on a personalised screen instead of an
        // unwelcoming blank canvas.
        GreetingHero(state = state, onAvatarClick = onShowSettings)
        Spacer(Modifier.height(Spacing.lg))

        if (!state.hasAnyTransactions) {
            EmptyDashboardCard()
            return@Column
        }

        // Combined year + month card, includes the daily-flow chart
        DashboardMainCard(
            state = state,
            onSelectYear = vm::selectYear,
            onSelectMonth = vm::selectMonth,
        )
        Spacer(Modifier.height(Spacing.lg))

        state.featuredInsight?.let { insight ->
            AIInsightCard(insight = insight, onTap = onOpenBudgi)
            Spacer(Modifier.height(Spacing.lg))
        }

        if (state.topCategories.isNotEmpty()) {
            TopCategoriesCard(state = state)
            Spacer(Modifier.height(Spacing.lg))
        }

        RecentTransactionsCard(state = state, onEdit = onEditTransaction)

        // 6-month income-vs-expense bar chart — same surface as iOS
        // IncomeExpenseBarChart at the bottom of the dashboard.
        if (state.sixMonthFlow.any { it.incomeMinor + it.expenseMinor > 0 }) {
            Spacer(Modifier.height(Spacing.lg))
            SixMonthBarChartCard(state = state)
        }
    }
}

// ── Greeting hero ──────────────────────────────────────────────────────────

@Composable
private fun GreetingHero(
    state: DashboardState,
    onAvatarClick: () -> Unit,
) {
    val context = LocalContext.current
    // First name only — the iOS hero is "İyi akşamlar, / Ozan 👋", we don't
    // want surnames pushing the line off the screen.
    val firstName = state.user?.displayName?.substringBefore(' ')?.takeIf { it.isNotBlank() }
        ?: state.user?.email?.substringBefore('@')
        ?: ""
    val greetingLabel = remember {
        val hour = java.time.LocalDateTime.now().hour
        val resId = when (hour) {
            in 5..11 -> R.string.dashboard_greeting_label_morning
            in 12..17 -> R.string.dashboard_greeting_label_afternoon
            in 18..22 -> R.string.dashboard_greeting_label_evening
            else -> R.string.dashboard_greeting_label_night
        }
        context.getString(resId)
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.xl, vertical = Spacing.lg),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            // Two-line iOS-style hero: small greeting on top, bold name below.
            Text(
                text = greetingLabel + ",",
                style = BrandText.subheadline,
                color = BrandColor.textSecondary(),
                maxLines = 1,
            )
            if (firstName.isNotBlank()) {
                Text(
                    text = "$firstName 👋",
                    style = BrandText.largeTitle,
                    color = BrandColor.textPrimary(),
                    maxLines = 1,
                )
            }
        }
        AvatarSmall(
            photoUrl = state.user?.photoURL,
            initial = firstName.firstOrNull()?.uppercase() ?: "?",
            onClick = onAvatarClick,
        )
    }
}

@Composable
private fun AvatarSmall(photoUrl: String?, initial: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .height(44.dp)
            .width(44.dp)
            .clip(androidx.compose.foundation.shape.CircleShape)
            .background(BrandColor.Primary.copy(alpha = 0.2f))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        if (!photoUrl.isNullOrBlank()) {
            coil.compose.AsyncImage(
                model = photoUrl,
                contentDescription = "Settings",
                modifier = Modifier
                    .height(44.dp)
                    .width(44.dp)
                    .clip(androidx.compose.foundation.shape.CircleShape),
                contentScale = androidx.compose.ui.layout.ContentScale.Crop,
            )
        } else {
            // Initials fallback — looks like iOS' colored circle for email/
            // password sign-ups that don't ship a photoURL.
            Text(
                text = initial,
                style = BrandText.subheadline.copy(
                    fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                ),
                color = BrandColor.Primary,
            )
        }
    }
}

// ── Combined year + month card (port of iOS DashboardMainCard) ─────────────

@Composable
private fun DashboardMainCard(
    state: DashboardState,
    onSelectYear: (Int) -> Unit,
    onSelectMonth: (Int) -> Unit,
) {
    Column(
        modifier = Modifier
            .padding(horizontal = Spacing.xl)
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(BrandColor.surface().copy(alpha = 0.5f)),
    ) {
        // Year section
        YearSection(state, onSelectYear)
        HorizontalDivider(
            color = BrandColor.borderSubtle(),
            modifier = Modifier.padding(horizontal = Spacing.lg),
        )
        // Month section + chart
        MonthSection(state, onSelectMonth)
    }
}

@Composable
private fun YearSection(state: DashboardState, onSelectYear: (Int) -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.lg, vertical = Spacing.md),
        verticalArrangement = Arrangement.spacedBy(Spacing.sm),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = stringResource(R.string.dashboard_yearly_summary),
                style = BrandText.caption,
                color = BrandColor.textTertiary(),
            )
            Spacer(Modifier.weight(1f))
            PickerPill(
                label = state.year.toString(),
                items = state.availableYears,
                onSelect = onSelectYear,
                itemLabel = { it.toString() },
            )
        }
        Row(modifier = Modifier.fillMaxWidth()) {
            YearStatColumn(
                arrow = "↑",
                label = stringResource(R.string.dashboard_year_income_label),
                amountMinor = state.yearIncomeMinor,
                color = BrandColor.Income,
                modifier = Modifier.weight(1f),
            )
            Box(
                modifier = Modifier
                    .width(1.dp)
                    .height(48.dp)
                    .background(BrandColor.borderSubtle()),
            )
            YearStatColumn(
                arrow = "↓",
                label = stringResource(R.string.dashboard_year_expense_label),
                amountMinor = state.yearExpenseMinor,
                color = BrandColor.Expense,
                modifier = Modifier.weight(1f),
            )
        }
    }
}

@Composable
private fun YearStatColumn(
    arrow: String,
    label: String,
    amountMinor: Long,
    color: Color,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.padding(horizontal = Spacing.sm),
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = arrow,
                style = BrandText.caption.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                color = color,
            )
            Spacer(Modifier.width(4.dp))
            Text(
                text = label,
                style = BrandText.caption,
                color = BrandColor.textTertiary(),
            )
        }
        // Slightly smaller than displayHero — year totals get long fast and
        // the iOS card already keeps these tighter than the month total.
        Text(
            text = com.budgetella.app.core.design.moneyText(amountMinor),
            style = BrandText.title.copy(
                fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
            ),
            color = color,
            maxLines = 1,
        )
    }
}

@Composable
private fun MonthSection(state: DashboardState, onSelectMonth: (Int) -> Unit) {
    val monthName = state.month.month.getDisplayName(TextStyle.FULL, Locale.getDefault())
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.lg, vertical = Spacing.md),
        verticalArrangement = Arrangement.spacedBy(Spacing.sm),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = stringResource(R.string.dashboard_active_month),
                style = BrandText.caption,
                color = BrandColor.textTertiary(),
            )
            Spacer(Modifier.weight(1f))
            PickerPill(
                label = monthName,
                items = state.availableMonths,
                onSelect = onSelectMonth,
                itemLabel = { m ->
                    java.time.Month.of(m).getDisplayName(TextStyle.FULL, Locale.getDefault())
                },
            )
        }
        Row(modifier = Modifier.fillMaxWidth()) {
            MonthStatColumn(
                arrow = "↗",
                label = stringResource(R.string.dashboard_income_label),
                amountMinor = state.incomeMinor,
                color = BrandColor.Income,
                modifier = Modifier.weight(1f),
            )
            MonthStatColumn(
                arrow = "↘",
                label = stringResource(R.string.dashboard_expense_label),
                amountMinor = state.expenseMinor,
                color = BrandColor.Expense,
                modifier = Modifier.weight(1f),
            )
        }
        // Net row
        val isNeg = state.netMinor < 0
        val netColor = if (isNeg) BrandColor.Expense else BrandColor.Income
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = if (isNeg) "↓" else "↑",
                style = BrandText.footnote.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                color = netColor,
            )
            Spacer(Modifier.width(4.dp))
            Text(
                text = stringResource(R.string.dashboard_net_short) + " " +
                    (if (isNeg) "−" else "+") +
                    com.budgetella.app.core.design.moneyText(
                        kotlin.math.abs(state.netMinor),
                    ) +
                    " (" + monthName + ")",
                style = BrandText.footnote,
                color = netColor,
            )
        }
        // Chart with legend
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.xs)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = stringResource(R.string.dashboard_flow_title) + " · " + monthName.uppercase(),
                    style = BrandText.caption,
                    color = BrandColor.textTertiary(),
                )
                Spacer(Modifier.weight(1f))
                LegendDot(BrandColor.Income, stringResource(R.string.dashboard_legend_income))
                Spacer(Modifier.width(Spacing.sm))
                LegendDot(BrandColor.Expense, stringResource(R.string.dashboard_legend_expense))
            }
            if (state.dailyFlow.any { it.incomeMinor + it.expenseMinor > 0 }) {
                EmbeddedFlowChart(state = state)
            }
        }
    }
}

@Composable
private fun MonthStatColumn(
    arrow: String,
    label: String,
    amountMinor: Long,
    color: Color,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = arrow,
                style = BrandText.caption,
                color = color,
            )
            Spacer(Modifier.width(4.dp))
            Text(
                text = label,
                style = BrandText.caption,
                color = BrandColor.textTertiary(),
            )
        }
        Text(
            text = com.budgetella.app.core.design.moneyText(amountMinor),
            style = BrandText.subheadline.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold),
            color = color,
            maxLines = 1,
        )
    }
}

/**
 * Year / month picker pill — tappable capsule that opens a DropdownMenu of
 * available choices. Mirrors the iOS pill style (background3 + chevron).
 */
@Composable
private fun <T> PickerPill(
    label: String,
    items: List<T>,
    onSelect: (T) -> Unit,
    itemLabel: (T) -> String,
) {
    var expanded by remember { mutableStateOf(false) }
    Box {
        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(Spacing.radiusFull))
                .background(BrandColor.background3())
                .clickable(enabled = items.isNotEmpty()) { expanded = true }
                .padding(start = Spacing.sm, end = 6.dp, top = 5.dp, bottom = 5.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = label,
                style = BrandText.caption,
                color = BrandColor.textPrimary(),
            )
            Spacer(Modifier.width(2.dp))
            Icon(
                imageVector = Icons.Filled.KeyboardArrowDown,
                contentDescription = null,
                tint = BrandColor.textTertiary(),
                modifier = Modifier.height(14.dp).width(14.dp),
            )
        }
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            modifier = Modifier.background(BrandColor.surface()),
        ) {
            items.forEach { item ->
                DropdownMenuItem(
                    text = {
                        Text(
                            text = itemLabel(item),
                            style = BrandText.body,
                            color = BrandColor.textPrimary(),
                        )
                    },
                    onClick = {
                        expanded = false
                        onSelect(item)
                    },
                )
            }
        }
    }
}

@Composable
private fun LegendDot(color: Color, label: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier
                .height(8.dp)
                .width(8.dp)
                .clip(RoundedCornerShape(2.dp))
                .background(color),
        )
        Spacer(Modifier.width(4.dp))
        Text(
            text = label,
            style = BrandText.caption,
            color = BrandColor.textTertiary(),
        )
    }
}

@Composable
private fun EmbeddedFlowChart(state: DashboardState) {
    // Single, stable producer for the whole composition — Vico requires the
    // producer instance to outlive data changes; pushing new series happens
    // via runTransaction inside the LaunchedEffect below.
    val producer = remember { CartesianChartModelProducer() }
    LaunchedEffect(state.dailyFlow) {
        producer.runTransaction {
            lineSeries {
                series(state.dailyFlow.map { it.incomeMinor.toFloat() })
                series(state.dailyFlow.map { it.expenseMinor.toFloat() })
            }
        }
    }
    CartesianChartHost(
        chart = rememberCartesianChart(
            rememberLineCartesianLayer(
                lineProvider = LineCartesianLayer.LineProvider.series(
                    LineCartesianLayer.rememberLine(
                        fill = LineCartesianLayer.LineFill.single(
                            fill = com.patrykandpatrick.vico.core.common.Fill(BrandColor.Income.toArgb()),
                        ),
                    ),
                    LineCartesianLayer.rememberLine(
                        fill = LineCartesianLayer.LineFill.single(
                            fill = com.patrykandpatrick.vico.core.common.Fill(BrandColor.Expense.toArgb()),
                        ),
                    ),
                ),
            ),
        ),
        modelProducer = producer,
        modifier = Modifier
            .fillMaxWidth()
            .height(120.dp),
        zoomState = rememberVicoZoomState(zoomEnabled = false),
    )
}

// ── Balance hero ───────────────────────────────────────────────────────────

@Composable
private fun BalanceHero(state: DashboardState) {
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
            text = com.budgetella.app.core.design.moneyText(state.netMinor),
            style = BrandText.displayHero,
            color = netColor,
        )

        Spacer(Modifier.height(Spacing.lg))
        Row(modifier = Modifier.fillMaxWidth()) {
            MoneyBlock(
                label = stringResource(R.string.dashboard_income_label),
                amountMinor = state.incomeMinor,
                accent = BrandColor.Income,
                modifier = Modifier.weight(1f),
            )
            Spacer(Modifier.width(Spacing.md))
            MoneyBlock(
                label = stringResource(R.string.dashboard_expense_label),
                amountMinor = state.expenseMinor,
                accent = BrandColor.Expense,
                modifier = Modifier.weight(1f),
            )
        }
    }
}

@Composable
private fun MoneyBlock(
    label: String,
    amountMinor: Long,
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
            text = com.budgetella.app.core.design.moneyText(amountMinor),
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
                        text = com.budgetella.app.core.locale.displayCategoryName(stat.category),
                        style = BrandText.subheadline,
                        color = BrandColor.textPrimary(),
                        modifier = Modifier.weight(1f),
                    )
                    Text(
                        text = com.budgetella.app.core.design.moneyText(
                            minorUnits = stat.amountMinor,
                            decimals = 0,
                        ),
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

// ── Six-month bar chart ────────────────────────────────────────────────────

@Composable
private fun SixMonthBarChartCard(state: DashboardState) {
    val producer = remember { CartesianChartModelProducer() }
    LaunchedEffect(state.sixMonthFlow) {
        producer.runTransaction {
            columnSeries {
                series(state.sixMonthFlow.map { it.incomeMinor.toFloat() })
                series(state.sixMonthFlow.map { it.expenseMinor.toFloat() })
            }
        }
    }
    val incomeArgb = BrandColor.Income.toArgb()
    val expenseArgb = BrandColor.Expense.toArgb()
    Column(
        modifier = Modifier
            .padding(horizontal = Spacing.xl)
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(BrandColor.surface().copy(alpha = 0.5f))
            .padding(Spacing.lg),
        verticalArrangement = Arrangement.spacedBy(Spacing.sm),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = stringResource(R.string.dashboard_six_month_title),
                style = BrandText.caption,
                color = BrandColor.textTertiary(),
            )
            Spacer(Modifier.weight(1f))
            LegendDot(BrandColor.Income, stringResource(R.string.dashboard_legend_income))
            Spacer(Modifier.width(Spacing.sm))
            LegendDot(BrandColor.Expense, stringResource(R.string.dashboard_legend_expense))
        }
        CartesianChartHost(
            chart = rememberCartesianChart(
                rememberColumnCartesianLayer(
                    columnProvider = ColumnCartesianLayer.ColumnProvider.series(
                        LineComponent(
                            fill = Fill(incomeArgb),
                            thicknessDp = 12f,
                            shape = CorneredShape.rounded(4f),
                        ),
                        LineComponent(
                            fill = Fill(expenseArgb),
                            thicknessDp = 12f,
                            shape = CorneredShape.rounded(4f),
                        ),
                    ),
                ),
            ),
            modelProducer = producer,
            modifier = Modifier
                .fillMaxWidth()
                .height(160.dp),
            zoomState = rememberVicoZoomState(zoomEnabled = false),
        )
    }
}

// ── AI insight card ────────────────────────────────────────────────────────

@Composable
internal fun AIInsightCard(insight: BudgiInsight, onTap: () -> Unit) {
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

/**
 * Empty-state card surfaced inline below the Greeting hero, so the screen
 * still feels personalised even on day one. A gradient panel with a centred
 * sparkle emoji and instruction lines that reference the FAB.
 */
@Composable
private fun EmptyDashboardCard() {
    Column(
        modifier = Modifier
            .padding(horizontal = Spacing.xl)
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusLarge))
            .background(
                androidx.compose.ui.graphics.Brush.linearGradient(
                    listOf(
                        BrandColor.Primary.copy(alpha = 0.22f),
                        BrandColor.PrimaryLight.copy(alpha = 0.08f),
                    )
                )
            )
            .padding(vertical = Spacing.xxl, horizontal = Spacing.xl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.md),
    ) {
        // Big emoji "icon" — cheap brand-on-feel for the empty state without
        // needing a custom illustration asset.
        Text(
            text = "✨",
            style = BrandText.displayHero,
        )
        Text(
            text = stringResource(R.string.dashboard_empty_title),
            style = BrandText.title,
            color = BrandColor.textPrimary(),
            textAlign = TextAlign.Center,
        )
        Text(
            text = stringResource(R.string.dashboard_empty_body),
            style = BrandText.body,
            color = BrandColor.textSecondary(),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(Spacing.sm))
        // Three feature hints — sets expectations for what shows up once the
        // user adds their first few entries.
        EmptyFeatureHint(
            emoji = "📊",
            label = stringResource(R.string.dashboard_empty_feature_charts),
        )
        EmptyFeatureHint(
            emoji = "🧠",
            label = stringResource(R.string.dashboard_empty_feature_ai),
        )
        EmptyFeatureHint(
            emoji = "🎯",
            label = stringResource(R.string.dashboard_empty_feature_categories),
        )
    }
}

@Composable
private fun EmptyFeatureHint(emoji: String, label: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(BrandColor.surface().copy(alpha = 0.4f))
            .padding(horizontal = Spacing.md, vertical = Spacing.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text = emoji, style = BrandText.title)
        Spacer(Modifier.width(Spacing.md))
        Text(
            text = label,
            style = BrandText.body,
            color = BrandColor.textPrimary(),
        )
    }
}

