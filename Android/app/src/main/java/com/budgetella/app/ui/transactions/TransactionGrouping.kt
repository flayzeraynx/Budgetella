package com.budgetella.app.ui.transactions

import com.budgetella.app.data.local.entity.TransactionEntity
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * Hierarchical year/month/day grouping — mirror of iOS TransactionYearGroup
 * → MonthGroup → DayGroup. Renderer (TransactionsScreen) walks the tree to
 * draw year, month, and day headers.
 */
data class TransactionYearGroup(
    val year: Int,
    val months: List<TransactionMonthGroup>,
)

data class TransactionMonthGroup(
    val year: Int,
    val month: Int,
    val days: List<TransactionDayGroup>,
)

data class TransactionDayGroup(
    val date: LocalDate,
    val transactions: List<TransactionEntity>,
)

/**
 * Bucket a flat transaction list into year/month/day groups. Empty input
 * returns an empty list — call sites should branch into the empty state.
 */
fun List<TransactionEntity>.groupedHierarchical(
    zone: ZoneId = ZoneId.systemDefault()
): List<TransactionYearGroup> {
    if (isEmpty()) return emptyList()

    return groupBy { tx -> Instant.ofEpochMilli(tx.date).atZone(zone).toLocalDate() }
        .toSortedMap(compareByDescending { it })           // newest day first
        .entries
        .groupBy { (date, _) -> date.year to date.monthValue }
        .toSortedMap(
            compareByDescending<Pair<Int, Int>> { it.first }
                .thenByDescending { it.second }
        )
        .entries
        .groupBy { (yearMonth, _) -> yearMonth.first }
        .toSortedMap(reverseOrder())
        .map { (year, monthBuckets) ->
            TransactionYearGroup(
                year = year,
                months = monthBuckets.map { (yearMonth, dayBuckets) ->
                    TransactionMonthGroup(
                        year = yearMonth.first,
                        month = yearMonth.second,
                        days = dayBuckets.map { (date, txs) ->
                            TransactionDayGroup(date, txs.sortedByDescending { it.date })
                        }
                    )
                }
            )
        }
}
