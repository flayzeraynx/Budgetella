package com.budgetella.app.ui.stats

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.budgetella.app.core.locale.LocaleHelper
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.model.TransactionType
import com.budgetella.app.data.prefs.UserPrefs
import com.budgetella.app.data.repository.CategoryRepository
import com.budgetella.app.data.repository.TransactionRepository
import com.budgetella.app.ui.budgi.BudgiInsight
import com.budgetella.app.ui.budgi.BudgiInsightEngine
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import java.time.Instant
import java.time.YearMonth
import java.time.ZoneId
import javax.inject.Inject

/** Per-category amount + share of selected-type total. */
data class CategoryStat(
    val category: CategoryEntity,
    val amountMinor: Long,
    val percentage: Float,           // 0f..1f
)

data class StatsUiState(
    /** Visible breakdown — flips between income and expense via the toggle.
     *  Default is Income to match the iOS shipping behaviour. */
    val showingType: TransactionType = TransactionType.Income,
)

data class StatsState(
    val ui: StatsUiState = StatsUiState(),
    val month: YearMonth = YearMonth.now(),
    val totalMinor: Long = 0L,
    val breakdown: List<CategoryStat> = emptyList(),
    /** Percent change vs previous month for the SAME [ui.showingType]. */
    val changeVsPrev: Float? = null,
    /** Random pick from the Budgi rule engine — same insight surface as Dashboard. */
    val featuredInsight: BudgiInsight? = null,
    /** Months with at least one transaction (+ the selected month) for the picker. */
    val availableMonths: List<YearMonth> = emptyList(),
)

@HiltViewModel
class StatsViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    transactionRepository: TransactionRepository,
    categoryRepository: CategoryRepository,
    userPrefs: UserPrefs,
) : ViewModel() {

    private val _ui = MutableStateFlow(StatsUiState())
    val ui: StateFlow<StatsUiState> = _ui.asStateFlow()

    // User-selected month. Defaults to current; the picker rewinds it.
    private val selectedMonth = MutableStateFlow(YearMonth.now())

    private val localeNonce = MutableStateFlow(0L)

    fun refreshLocale() {
        localeNonce.value += 1
    }

    fun selectMonth(month: YearMonth) {
        selectedMonth.value = month
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    private val transactions: StateFlow<List<TransactionEntity>> = userPrefs.currentUserId
        .flatMapLatest { uid -> transactionRepository.observeAll(uid) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    @OptIn(ExperimentalCoroutinesApi::class)
    private val categories: StateFlow<List<CategoryEntity>> = userPrefs.currentUserId
        .flatMapLatest { uid -> categoryRepository.observeAll(uid) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val state: StateFlow<StatsState> = combine(
        transactions,
        categories,
        _ui,
        selectedMonth,
        localeNonce,
    ) { values ->
        @Suppress("UNCHECKED_CAST")
        val txs = values[0] as List<TransactionEntity>
        @Suppress("UNCHECKED_CAST")
        val cats = values[1] as List<CategoryEntity>
        val ui = values[2] as StatsUiState
        val month = values[3] as YearMonth
        compute(txs, cats, ui, month)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), StatsState())

    fun toggleType(type: TransactionType) {
        _ui.update { it.copy(showingType = type) }
    }

    // ── Pure compute ──────────────────────────────────────────────────────

    private fun compute(
        transactions: List<TransactionEntity>,
        categories: List<CategoryEntity>,
        ui: StatsUiState,
        month: YearMonth,
    ): StatsState {
        val zone = ZoneId.systemDefault()
        val monthStart = month.atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val nextMonth = month.plusMonths(1).atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val prevStart = month.minusMonths(1).atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()

        val current = transactions.filter { it.date in monthStart until nextMonth && it.type == ui.showingType }
        val previous = transactions.filter { it.date in prevStart until monthStart && it.type == ui.showingType }

        val totalMinor = current.sumOf { it.amount }
        val previousMinor = previous.sumOf { it.amount }

        val catById = categories.associateBy { it.id }
        val byCategory = current
            .filter { it.categoryId != null }
            .groupBy { it.categoryId!! }
            .mapNotNull { (id, txs) ->
                catById[id]?.let { cat ->
                    CategoryStat(
                        category = cat,
                        amountMinor = txs.sumOf { it.amount },
                        percentage = if (totalMinor == 0L) 0f else
                            txs.sumOf { it.amount }.toFloat() / totalMinor.toFloat(),
                    )
                }
            }
            .sortedByDescending { it.amountMinor }

        val change: Float? = if (previousMinor == 0L) {
            null
        } else {
            ((totalMinor - previousMinor).toFloat() / previousMinor.toFloat()) * 100f
        }

        // Budgi rule insight — shared with Dashboard. Random pick keeps the
        // surface lively when there are multiple rules firing.
        val insights = BudgiInsightEngine.compute(
            transactions = transactions,
            categories = categories,
            language = LocaleHelper.currentLanguage(context).tag,
            categoryDisplayName = { cat ->
                com.budgetella.app.core.locale.displayCategoryName(cat, context)
            },
        )
        val featured = insights.randomOrNull()

        // Month picker list: every month that contains a transaction, newest
        // first. Always include the currently selected month so the user can
        // see empty periods if they pick one.
        val monthsWithData = transactions
            .map { Instant.ofEpochMilli(it.date).atZone(zone) }
            .map { YearMonth.of(it.year, it.monthValue) }
            .distinct()
            .sortedDescending()
        val availableMonths = (monthsWithData + month).distinct().sortedDescending()

        return StatsState(
            ui = ui,
            month = month,
            totalMinor = totalMinor,
            breakdown = byCategory,
            changeVsPrev = change,
            featuredInsight = featured,
            availableMonths = availableMonths,
        )
    }
}
