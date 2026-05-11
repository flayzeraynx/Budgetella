package com.budgetella.app.ui.transactions

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.model.Money
import com.budgetella.app.data.model.RecurringInterval
import com.budgetella.app.data.model.TransactionStatus
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
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

/** Mutable form state for the add/edit bottom sheet. */
data class TransactionFormState(
    val editingId: String? = null,           // null when adding
    val type: TransactionType = TransactionType.Expense,
    val amountInput: String = "",            // raw text — parsed on save
    val categoryId: String? = null,
    val note: String = "",
    val dateMillis: Long = System.currentTimeMillis(),
    val isRecurring: Boolean = false,
    val recurringInterval: RecurringInterval = RecurringInterval.Monthly,
    val saving: Boolean = false,
) {
    val isEditing: Boolean get() = editingId != null

    /** A best-effort parse of [amountInput]. Returns 0 minor-units on garbage. */
    fun parsedAmount(): Money = Money.parseMajorOrNull(amountInput) ?: Money.Zero

    val canSave: Boolean
        get() = !saving && parsedAmount().minorUnits > 0 && categoryId != null
}

/**
 * Drives the AddEditTransactionSheet. The same view-model handles both add
 * (editingId == null) and edit (editingId set via [startEdit]).
 *
 * On save:
 *  - Builds a TransactionEntity from the form state + active user id.
 *  - Calls TransactionRepository.upsert — Room first, then Firestore mirror.
 *  - Returns to the caller via the `onDismiss` callback.
 */
@HiltViewModel
class AddEditTransactionViewModel @Inject constructor(
    private val transactionRepository: TransactionRepository,
    categoryRepository: CategoryRepository,
    private val userPrefs: UserPrefs,
) : ViewModel() {

    private val _form = MutableStateFlow(TransactionFormState())
    val form: StateFlow<TransactionFormState> = _form.asStateFlow()

    @OptIn(ExperimentalCoroutinesApi::class)
    val categories: StateFlow<List<CategoryEntity>> = userPrefs.currentUserId
        .flatMapLatest { uid -> categoryRepository.observeAll(uid) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    // ── State setters ─────────────────────────────────────────────────────

    /** Reset to a blank add form, pre-selecting the default expense category. */
    fun startAdd() {
        _form.value = TransactionFormState()
        // First-category default is set lazily once the categories flow emits;
        // see the consumer below in AddEditTransactionSheet.
    }

    fun startEdit(transaction: TransactionEntity) {
        _form.value = TransactionFormState(
            editingId = transaction.id,
            type = transaction.type,
            amountInput = Money(transaction.amount).toBigDecimal().toPlainString(),
            categoryId = transaction.categoryId,
            note = transaction.note,
            dateMillis = transaction.date,
            isRecurring = transaction.isRecurring,
            recurringInterval = transaction.recurringIntervalRaw
                ?.let { RecurringInterval.fromRaw(it) }
                ?: RecurringInterval.Monthly,
        )
    }

    fun setType(type: TransactionType) {
        _form.update {
            it.copy(
                type = type,
                // Clear the category if it doesn't match the new type — the UI
                // will re-suggest the first one of the right type.
                categoryId = it.categoryId?.takeIf { id ->
                    categories.value.firstOrNull { c -> c.id == id }?.type == type
                }
            )
        }
    }

    fun setAmountInput(value: String) {
        // Keep digits + one decimal separator. Letters and other punctuation
        // can't make a valid amount anyway, so reject them at the gate.
        val cleaned = value.filter { it.isDigit() || it == '.' || it == ',' }
        _form.update { it.copy(amountInput = cleaned) }
    }

    fun setCategory(id: String) = _form.update { it.copy(categoryId = id) }
    fun setNote(value: String) = _form.update { it.copy(note = value) }
    fun setDate(millis: Long) = _form.update { it.copy(dateMillis = millis) }
    fun setRecurring(value: Boolean) = _form.update { it.copy(isRecurring = value) }
    fun setRecurringInterval(value: RecurringInterval) =
        _form.update { it.copy(recurringInterval = value) }

    /** Pre-select the first category of the active type if none is selected yet. */
    fun ensureCategoryDefault() {
        if (_form.value.categoryId != null) return
        val first = categories.value.firstOrNull { it.type == _form.value.type } ?: return
        _form.update { it.copy(categoryId = first.id) }
    }

    // ── Actions ───────────────────────────────────────────────────────────

    fun save(onDone: () -> Unit) {
        val f = _form.value
        if (!f.canSave) return
        _form.update { it.copy(saving = true) }
        viewModelScope.launch {
            val uid = userPrefs.currentUserId.first()
            val now = System.currentTimeMillis()
            val entity = TransactionEntity(
                id = f.editingId ?: UUID.randomUUID().toString(),
                userId = uid,
                typeRaw = f.type.raw,
                amount = f.parsedAmount().minorUnits,
                currency = "TRY",
                note = f.note.trim(),
                date = f.dateMillis,
                statusRaw = TransactionStatus.Completed.raw,
                isRecurring = f.isRecurring,
                recurringIntervalRaw = if (f.isRecurring) f.recurringInterval.raw else null,
                categoryId = f.categoryId,
                createdAt = if (f.isEditing) now else now,    // upsert preserves on conflict via REPLACE — set both for safety
                updatedAt = now,
            )
            transactionRepository.upsert(entity)
            _form.update { it.copy(saving = false) }
            onDone()
        }
    }

    fun delete(onDone: () -> Unit) {
        val id = _form.value.editingId ?: return
        viewModelScope.launch {
            transactionRepository.delete(id)
            onDone()
        }
    }
}
