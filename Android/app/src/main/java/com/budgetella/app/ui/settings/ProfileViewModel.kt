package com.budgetella.app.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.budgetella.app.data.model.TransactionType
import com.budgetella.app.data.prefs.UserPrefs
import com.budgetella.app.data.repository.TransactionRepository
import com.budgetella.app.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import javax.inject.Inject

/**
 * View state for [ProfileSheet]. Aggregates the cached UserEntity with a
 * cheap pass over the transactions table to derive at-a-glance stats —
 * mirrors iOS ProfileView's computed properties.
 */
data class ProfileUiState(
    val displayName: String? = null,
    val email: String? = null,
    val photoUrl: String? = null,
    val transactionCount: Int = 0,
    /** Lifetime income minus expense, clamped to 0 — matches iOS Tasarruf tile. */
    val totalSavedMinor: Long = 0,
    /** Current calendar-month income minus expense (can be negative). */
    val monthSavedMinor: Long = 0,
    val monthIncomeMinor: Long = 0,
    val monthExpenseMinor: Long = 0,
    val dailyStreak: Int = 0,
)

@HiltViewModel
class ProfileViewModel @Inject constructor(
    userPrefs: UserPrefs,
    userRepository: UserRepository,
    transactionRepository: TransactionRepository,
) : ViewModel() {

    @OptIn(ExperimentalCoroutinesApi::class)
    val state: StateFlow<ProfileUiState> = userPrefs.currentUserId
        .flatMapLatest { uid ->
            combine(
                userRepository.observeUser(uid),
                transactionRepository.observeAll(uid),
            ) { user, txs ->
                val lifetimeIncome = txs.filter { it.type == TransactionType.Income }.sumOf { it.amount }
                val lifetimeExpense = txs.filter { it.type == TransactionType.Expense }.sumOf { it.amount }
                val lifetimeNet = lifetimeIncome - lifetimeExpense

                // This-month window for the "Bu Ay" tiles — port of iOS
                // ProfileView.monthSavings.
                val zone = ZoneId.systemDefault()
                val monthStart = YearMonth.now(zone).atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
                val monthTxs = txs.filter { it.date >= monthStart }
                val monthIncome = monthTxs.filter { it.type == TransactionType.Income }.sumOf { it.amount }
                val monthExpense = monthTxs.filter { it.type == TransactionType.Expense }.sumOf { it.amount }

                ProfileUiState(
                    displayName = user?.displayName,
                    email = user?.email,
                    photoUrl = user?.photoURL,
                    transactionCount = txs.size,
                    // "Toplam tasarruf" is a savings tile — never display a
                    // negative number, mirrors iOS `totalSavings >= 0 ? … : ₺0`.
                    totalSavedMinor = lifetimeNet.coerceAtLeast(0L),
                    monthSavedMinor = monthIncome - monthExpense,
                    monthIncomeMinor = monthIncome,
                    monthExpenseMinor = monthExpense,
                    dailyStreak = computeStreak(txs.map { it.date }),
                )
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ProfileUiState())

    /**
     * Same algorithm as iOS ProfileView.streak: walk back day-by-day from
     * today, counting consecutive days that contain at least one transaction.
     * Bails out at 365 days as a safety net.
     */
    private fun computeStreak(timestamps: List<Long>): Int {
        if (timestamps.isEmpty()) return 0
        val zone = ZoneId.systemDefault()
        val days: Set<LocalDate> = timestamps
            .map { java.time.Instant.ofEpochMilli(it).atZone(zone).toLocalDate() }
            .toSet()
        var day = LocalDate.now(zone)
        var count = 0
        while (count < 365 && day in days) {
            count++
            day = day.minusDays(1)
        }
        return count
    }
}
