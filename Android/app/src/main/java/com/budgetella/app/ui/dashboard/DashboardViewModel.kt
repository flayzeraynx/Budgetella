package com.budgetella.app.ui.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import android.content.Context
import com.budgetella.app.core.locale.LocaleHelper
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.local.entity.UserEntity
import com.budgetella.app.data.model.TransactionType
import com.budgetella.app.data.prefs.UserPrefs
import com.budgetella.app.data.repository.CategoryRepository
import com.budgetella.app.data.repository.TransactionRepository
import com.budgetella.app.data.repository.UserRepository
import com.budgetella.app.ui.budgi.BudgiInsight
import com.budgetella.app.ui.budgi.BudgiInsightEngine
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import javax.inject.Inject

/** Snapshot of a single category contributing to current-month spend. */
data class TopCategoryStat(
    val category: CategoryEntity,
    val amountMinor: Long,
    val percentageOfExpense: Float,    // 0f..1f
)

/** Per-day net flow point for the chart. */
data class DailyFlowPoint(
    val date: LocalDate,
    val incomeMinor: Long,
    val expenseMinor: Long,
) {
    val netMinor: Long get() = incomeMinor - expenseMinor
}

/** One month's income/expense aggregate for the 6-month bar chart. */
data class MonthlyFlowPoint(
    val month: YearMonth,
    val incomeMinor: Long,
    val expenseMinor: Long,
)

/** Top-level shape consumed by [com.budgetella.app.ui.dashboard.DashboardScreen]. */
data class DashboardState(
    val year: Int = YearMonth.now().year,
    val month: YearMonth = YearMonth.now(),
    val yearIncomeMinor: Long = 0L,
    val yearExpenseMinor: Long = 0L,
    val incomeMinor: Long = 0L,
    val expenseMinor: Long = 0L,
    val dailyFlow: List<DailyFlowPoint> = emptyList(),
    val topCategories: List<TopCategoryStat> = emptyList(),
    val recentTransactions: List<TransactionEntity> = emptyList(),
    val recentCategoriesById: Map<String, CategoryEntity> = emptyMap(),
    /** Random pick from the BudgiInsightEngine output; null when no data yet. */
    val featuredInsight: BudgiInsight? = null,
    val user: UserEntity? = null,
    /** Years that contain at least one transaction — picker menu source. */
    val availableYears: List<Int> = emptyList(),
    /** Months that contain at least one transaction in [year]. */
    val availableMonths: List<Int> = emptyList(),
    /** Last 6 calendar months ending in the selected month — bar chart input. */
    val sixMonthFlow: List<MonthlyFlowPoint> = emptyList(),
) {
    val netMinor: Long get() = incomeMinor - expenseMinor
    val hasAnyTransactions: Boolean get() = recentTransactions.isNotEmpty()
}

@HiltViewModel
class DashboardViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    transactionRepository: TransactionRepository,
    categoryRepository: CategoryRepository,
    userRepository: UserRepository,
    userPrefs: UserPrefs,
) : ViewModel() {

    @OptIn(ExperimentalCoroutinesApi::class)
    private val transactions: StateFlow<List<TransactionEntity>> = userPrefs.currentUserId
        .flatMapLatest { uid -> transactionRepository.observeAll(uid) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    @OptIn(ExperimentalCoroutinesApi::class)
    private val categories: StateFlow<List<CategoryEntity>> = userPrefs.currentUserId
        .flatMapLatest { uid -> categoryRepository.observeAll(uid) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    @OptIn(ExperimentalCoroutinesApi::class)
    private val user: StateFlow<UserEntity?> = userPrefs.currentUserId
        .flatMapLatest { uid -> userRepository.observeUser(uid) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    // User-selected viewing window. Defaults to the current year + month at
    // first compose; the user can rewind via the year/month pickers in
    // DashboardMainCard.
    private val selectedYear = kotlinx.coroutines.flow.MutableStateFlow(YearMonth.now().year)
    private val selectedMonth = kotlinx.coroutines.flow.MutableStateFlow(YearMonth.now().monthValue)

    /**
     * Public knob to force a state recompute — the Dashboard's BudgiInsight
     * card resolves its copy via [LocaleHelper.currentLanguage] inside
     * [compute], so a language switch needs to trigger a fresh compute. The
     * Composable calls [refreshLocale] from a LaunchedEffect keyed on the
     * Configuration's language tag; bumping this Long invalidates the combine.
     */
    private val localeNonce = kotlinx.coroutines.flow.MutableStateFlow(0L)

    fun refreshLocale() {
        localeNonce.value += 1
    }

    fun selectYear(year: Int) {
        selectedYear.value = year
        val today = LocalDate.now()
        // Clamp month if we jump back to a year that hasn't reached the
        // currently selected month yet (e.g. selecting 2024 when today is May).
        val maxMonth = if (year == today.year) today.monthValue else 12
        if (selectedMonth.value > maxMonth) selectedMonth.value = maxMonth
    }

    fun selectMonth(month: Int) {
        selectedMonth.value = month
    }

    val state: StateFlow<DashboardState> = combine(
        transactions,
        categories,
        user,
        selectedYear,
        selectedMonth,
        localeNonce,
    ) { values ->
        @Suppress("UNCHECKED_CAST")
        val txs = values[0] as List<TransactionEntity>
        @Suppress("UNCHECKED_CAST")
        val cats = values[1] as List<CategoryEntity>
        val u = values[2] as UserEntity?
        val year = values[3] as Int
        val monthValue = values[4] as Int
        // localeNonce (values[5]) is consumed for invalidation only — compute
        // reads LocaleHelper.currentLanguage(context) directly.
        compute(txs, cats, year, monthValue).copy(user = u)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), DashboardState())

    // ── Pure compute (testable, no Dispatchers) ─────────────────────────────

    private fun compute(
        transactions: List<TransactionEntity>,
        categories: List<CategoryEntity>,
        year: Int = YearMonth.now().year,
        monthValue: Int = YearMonth.now().monthValue,
    ): DashboardState {
        val zone = ZoneId.systemDefault()
        val today = LocalDate.now(zone)
        val month = YearMonth.of(year, monthValue)
        val monthStart = month.atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val nextMonthStart = month.plusMonths(1).atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()

        // Year-window — Jan 1 through Jan 1 of the next year, in local TZ.
        val yearStart = month.withMonth(1).atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val nextYearStart = month.withMonth(1).atDay(1).plusYears(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val yearTxs = transactions.filter { it.date in yearStart until nextYearStart }
        val yearIncomeMinor = yearTxs.filter { it.type == TransactionType.Income }.sumOf { it.amount }
        val yearExpenseMinor = yearTxs.filter { it.type == TransactionType.Expense }.sumOf { it.amount }

        // Filter to current month — all aggregates below operate on this set.
        val monthTxs = transactions.filter { it.date in monthStart until nextMonthStart }

        val incomeMinor = monthTxs.filter { it.type == TransactionType.Income }.sumOf { it.amount }
        val expenseMinor = monthTxs.filter { it.type == TransactionType.Expense }.sumOf { it.amount }

        // Cap the daily-flow chart at month length for past months, or today
        // for the current month so we don't draw a flat zero tail.
        val maxDay = if (year == today.year && monthValue == today.monthValue) today.dayOfMonth
                     else month.lengthOfMonth()
        val dailyFlow = buildDailyFlow(monthTxs, zone, month, maxDay)
        val topCategories = topExpenseCategories(monthTxs, categories, expenseMinor, limit = 4)

        // Last 5 across all transactions (not just this month) so a brand-new
        // month still shows context from the prior one.
        val recent = transactions
            .sortedByDescending { it.date }
            .take(5)
        val categoryById = categories.associateBy { it.id }

        val insights = BudgiInsightEngine.compute(
            transactions = transactions,
            categories = categories,
            language = LocaleHelper.currentLanguage(context).tag,
            categoryDisplayName = { cat ->
                com.budgetella.app.core.locale.displayCategoryName(cat, context)
            },
        )
        val featured = insights.randomOrNull()

        // Pickers — every year/month that has at least one transaction, plus
        // current year so a brand-new account still gets a menu entry.
        val zoneRef = zone
        val years = (transactions.map { Instant.ofEpochMilli(it.date).atZone(zoneRef).year } + today.year)
            .distinct().sortedDescending()
        val monthsInYear = transactions
            .map { Instant.ofEpochMilli(it.date).atZone(zoneRef) }
            .filter { it.year == year }
            .map { it.monthValue }
            .distinct()
            .sortedDescending()
            .let { existing ->
                // Always include the currently-selected month so the user can
                // see the empty period if they want to.
                if (monthValue in existing) existing else (existing + monthValue).sortedDescending()
            }

        // 6-month rolling window ending at the currently selected month.
        val sixMonth = buildList {
            (5 downTo 0).forEach { offset ->
                val ym = month.minusMonths(offset.toLong())
                val start = ym.atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
                val end = ym.plusMonths(1).atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
                val window = transactions.filter { it.date in start until end }
                add(
                    MonthlyFlowPoint(
                        month = ym,
                        incomeMinor = window.filter { it.type == TransactionType.Income }.sumOf { it.amount },
                        expenseMinor = window.filter { it.type == TransactionType.Expense }.sumOf { it.amount },
                    )
                )
            }
        }

        return DashboardState(
            year = month.year,
            month = month,
            yearIncomeMinor = yearIncomeMinor,
            yearExpenseMinor = yearExpenseMinor,
            incomeMinor = incomeMinor,
            expenseMinor = expenseMinor,
            dailyFlow = dailyFlow,
            topCategories = topCategories,
            recentTransactions = recent,
            recentCategoriesById = categoryById,
            featuredInsight = featured,
            availableYears = years,
            availableMonths = monthsInYear,
            sixMonthFlow = sixMonth,
        )
    }

    private fun buildDailyFlow(
        monthTxs: List<TransactionEntity>,
        zone: ZoneId,
        month: YearMonth,
        upToDayOfMonth: Int,
    ): List<DailyFlowPoint> {
        if (monthTxs.isEmpty()) return emptyList()
        val grouped = monthTxs.groupBy { Instant.ofEpochMilli(it.date).atZone(zone).toLocalDate() }
        return (1..upToDayOfMonth).map { day ->
            val date = month.atDay(day)
            val sameDay = grouped[date].orEmpty()
            DailyFlowPoint(
                date = date,
                incomeMinor = sameDay.filter { it.type == TransactionType.Income }.sumOf { it.amount },
                expenseMinor = sameDay.filter { it.type == TransactionType.Expense }.sumOf { it.amount },
            )
        }
    }

    private fun topExpenseCategories(
        monthTxs: List<TransactionEntity>,
        categories: List<CategoryEntity>,
        totalExpenseMinor: Long,
        limit: Int,
    ): List<TopCategoryStat> {
        if (totalExpenseMinor == 0L) return emptyList()
        val byCategory = monthTxs
            .filter { it.type == TransactionType.Expense && it.categoryId != null }
            .groupBy { it.categoryId!! }
            .mapValues { (_, txs) -> txs.sumOf { it.amount } }
        val catById = categories.associateBy { it.id }
        return byCategory.entries
            .mapNotNull { (id, amount) ->
                catById[id]?.let { cat ->
                    TopCategoryStat(
                        category = cat,
                        amountMinor = amount,
                        percentageOfExpense = amount.toFloat() / totalExpenseMinor.toFloat(),
                    )
                }
            }
            .sortedByDescending { it.amountMinor }
            .take(limit)
    }
}
