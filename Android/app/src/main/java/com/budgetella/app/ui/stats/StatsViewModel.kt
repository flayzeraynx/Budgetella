package com.budgetella.app.ui.stats

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.model.TransactionType
import com.budgetella.app.data.prefs.UserPrefs
import com.budgetella.app.data.repository.CategoryRepository
import com.budgetella.app.data.repository.TransactionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
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
    /** Visible breakdown — flips between income and expense via the toggle. */
    val showingType: TransactionType = TransactionType.Expense,
)

data class StatsState(
    val ui: StatsUiState = StatsUiState(),
    val month: YearMonth = YearMonth.now(),
    val totalMinor: Long = 0L,
    val breakdown: List<CategoryStat> = emptyList(),
    /** Percent change vs previous month for the SAME [ui.showingType]. */
    val changeVsPrev: Float? = null,
)

@HiltViewModel
class StatsViewModel @Inject constructor(
    transactionRepository: TransactionRepository,
    categoryRepository: CategoryRepository,
    userPrefs: UserPrefs,
) : ViewModel() {

    private val _ui = MutableStateFlow(StatsUiState())
    val ui: StateFlow<StatsUiState> = _ui.asStateFlow()

    @OptIn(ExperimentalCoroutinesApi::class)
    private val transactions: StateFlow<List<TransactionEntity>> = userPrefs.currentUserId
        .flatMapLatest { uid -> transactionRepository.observeAll(uid) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    @OptIn(ExperimentalCoroutinesApi::class)
    private val categories: StateFlow<List<CategoryEntity>> = userPrefs.currentUserId
        .flatMapLatest { uid -> categoryRepository.observeAll(uid) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val state: StateFlow<StatsState> = combine(transactions, categories, _ui) { txs, cats, ui ->
        compute(txs, cats, ui)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), StatsState())

    fun toggleType(type: TransactionType) {
        _ui.update { it.copy(showingType = type) }
    }

    // ── Pure compute ──────────────────────────────────────────────────────

    private fun compute(
        transactions: List<TransactionEntity>,
        categories: List<CategoryEntity>,
        ui: StatsUiState,
    ): StatsState {
        val zone = ZoneId.systemDefault()
        val month = YearMonth.now(zone)
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

        return StatsState(
            ui = ui,
            month = month,
            totalMinor = totalMinor,
            breakdown = byCategory,
            changeVsPrev = change,
        )
    }
}
