package com.budgetella.app.ui.transactions

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
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/** Filter state mirrors iOS TransactionsViewModel — type pill + later, category chip. */
data class TransactionsUiState(
    val typeFilter: TransactionType? = null,        // null = All
    val categoryFilter: String? = null,             // category id, or null
)

@HiltViewModel
class TransactionsViewModel @Inject constructor(
    private val transactionRepository: TransactionRepository,
    private val categoryRepository: CategoryRepository,
    userPrefs: UserPrefs,
) : ViewModel() {

    private val _ui = MutableStateFlow(TransactionsUiState())
    val ui: StateFlow<TransactionsUiState> = _ui.asStateFlow()

    // Active user id, observed from prefs. Once auth lands and assigns a real
    // UID, the flow re-emits and the downstream Room flows re-bind.
    @OptIn(ExperimentalCoroutinesApi::class)
    private val transactions: StateFlow<List<TransactionEntity>> = userPrefs.currentUserId
        .flatMapLatest { uid -> transactionRepository.observeAll(uid) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    @OptIn(ExperimentalCoroutinesApi::class)
    val categories: StateFlow<List<CategoryEntity>> = userPrefs.currentUserId
        .flatMapLatest { uid -> categoryRepository.observeAll(uid) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    /**
     * Year/month/day grouped, type-filtered. Recomputed whenever transactions,
     * categories, or the type filter changes.
     */
    val groupedTransactions: StateFlow<List<TransactionYearGroup>> = combine(
        transactions,
        _ui,
    ) { txs, ui ->
        val filtered = txs.filter { tx ->
            (ui.typeFilter == null || tx.type == ui.typeFilter) &&
                (ui.categoryFilter == null || tx.categoryId == ui.categoryFilter)
        }
        filtered.groupedHierarchical()
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    /** Single source of truth for "is the list empty after filters?". */
    val isEmpty: StateFlow<Boolean> = combine(transactions, _ui) { txs, ui ->
        txs.none { tx ->
            (ui.typeFilter == null || tx.type == ui.typeFilter) &&
                (ui.categoryFilter == null || tx.categoryId == ui.categoryFilter)
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), true)

    val hasAnyTransactions: StateFlow<Boolean> = transactions
        .map { it.isNotEmpty() }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)

    // ── Actions ───────────────────────────────────────────────────────────

    fun setTypeFilter(type: TransactionType?) {
        _ui.update { it.copy(typeFilter = type) }
    }

    fun setCategoryFilter(categoryId: String?) {
        _ui.update { it.copy(categoryFilter = categoryId) }
    }

    fun delete(transaction: TransactionEntity) {
        viewModelScope.launch { transactionRepository.delete(transaction.id) }
    }
}
