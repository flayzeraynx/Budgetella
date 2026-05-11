package com.budgetella.app.ui.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import android.content.Context
import com.budgetella.app.core.locale.LocaleHelper
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.model.TransactionType
import com.budgetella.app.data.prefs.UserPrefs
import com.budgetella.app.data.repository.CategoryRepository
import com.budgetella.app.data.repository.TransactionRepository
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

/** Top-level shape consumed by [com.budgetella.app.ui.dashboard.DashboardScreen]. */
data class DashboardState(
    val month: YearMonth = YearMonth.now(),
    val incomeMinor: Long = 0L,
    val expenseMinor: Long = 0L,
    val dailyFlow: List<DailyFlowPoint> = emptyList(),
    val topCategories: List<TopCategoryStat> = emptyList(),
    val recentTransactions: List<TransactionEntity> = emptyList(),
    val recentCategoriesById: Map<String, CategoryEntity> = emptyMap(),
    /** Random pick from the BudgiInsightEngine output; null when no data yet. */
    val featuredInsight: BudgiInsight? = null,
) {
    val netMinor: Long get() = incomeMinor - expenseMinor
    val hasAnyTransactions: Boolean get() = recentTransactions.isNotEmpty()
}

@HiltViewModel
class DashboardViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    transactionRepository: TransactionRepository,
    categoryRepository: CategoryRepository,
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

    val state: StateFlow<DashboardState> = combine(transactions, categories) { txs, cats ->
        compute(txs, cats)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), DashboardState())

    // ── Pure compute (testable, no Dispatchers) ─────────────────────────────

    private fun compute(
        transactions: List<TransactionEntity>,
        categories: List<CategoryEntity>,
    ): DashboardState {
        val zone = ZoneId.systemDefault()
        val today = LocalDate.now(zone)
        val month = YearMonth.from(today)
        val monthStart = month.atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val nextMonthStart = month.plusMonths(1).atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()

        // Filter to current month — all aggregates below operate on this set.
        val monthTxs = transactions.filter { it.date in monthStart until nextMonthStart }

        val incomeMinor = monthTxs.filter { it.type == TransactionType.Income }.sumOf { it.amount }
        val expenseMinor = monthTxs.filter { it.type == TransactionType.Expense }.sumOf { it.amount }

        val dailyFlow = buildDailyFlow(monthTxs, zone, today.dayOfMonth)
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
        )
        val featured = insights.randomOrNull()

        return DashboardState(
            month = month,
            incomeMinor = incomeMinor,
            expenseMinor = expenseMinor,
            dailyFlow = dailyFlow,
            topCategories = topCategories,
            recentTransactions = recent,
            recentCategoriesById = categoryById,
            featuredInsight = featured,
        )
    }

    private fun buildDailyFlow(
        monthTxs: List<TransactionEntity>,
        zone: ZoneId,
        upToDayOfMonth: Int,
    ): List<DailyFlowPoint> {
        if (monthTxs.isEmpty()) return emptyList()
        val grouped = monthTxs.groupBy { Instant.ofEpochMilli(it.date).atZone(zone).toLocalDate() }
        return (1..upToDayOfMonth).map { day ->
            val date = YearMonth.now(zone).atDay(day)
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
