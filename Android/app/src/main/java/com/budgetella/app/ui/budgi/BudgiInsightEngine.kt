package com.budgetella.app.ui.budgi

import androidx.compose.ui.graphics.Color
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.model.Money
import com.budgetella.app.data.model.TransactionType
import java.time.YearMonth
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import kotlin.math.abs

/** A surfaced Budgi tip — rule-based, computed locally. */
data class BudgiInsight(
    val tag: String,              // localised tag ("SAVING", "OVER BUDGET", "TOP CATEGORY"…)
    val accent: Accent,           // colour family for the chip / card
    val text: String,             // full sentence
    val redactedText: String,     // shown when hideAmounts is on
) {
    enum class Accent { Primary, Income, Expense, Warning, Info }

    fun color(): Color = when (accent) {
        Accent.Income -> BrandColor.Income
        Accent.Expense -> BrandColor.Expense
        Accent.Warning -> BrandColor.Warning
        Accent.Info -> BrandColor.Info
        Accent.Primary -> BrandColor.Primary
    }
}

/**
 * Port of iOS BudgiInsightEngine.compute(). Pure function — same inputs
 * always produce the same insights, which means the UI layer can memoise it
 * keyed on the @Query counts (same trick we used on iOS DashboardCards).
 *
 * The returned list is ordered the way the iOS app surfaces them: savings,
 * top category, month-over-month, biggest expense, daily average.
 */
object BudgiInsightEngine {

    fun compute(
        transactions: List<TransactionEntity>,
        categories: List<CategoryEntity>,
        language: String = "en",
    ): List<BudgiInsight> {
        val zone = ZoneId.systemDefault()
        val month = YearMonth.now(zone)
        val monthStart = month.atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val nextMonth = month.plusMonths(1).atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val prevStart = month.minusMonths(1).atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()

        val current = transactions.filter { it.date in monthStart until nextMonth }
        val previous = transactions.filter { it.date in prevStart until monthStart }
        if (current.isEmpty()) return emptyList()

        val isEn = language.startsWith("en", ignoreCase = true)
        val results = mutableListOf<BudgiInsight>()

        savings(current, isEn)?.let(results::add)
        topCategory(current, categories, isEn)?.let(results::add)
        monthOverMonth(current, previous, isEn)?.let(results::add)
        biggestExpense(current, isEn)?.let(results::add)
        dailyAverage(current, zone, isEn)?.let(results::add)

        return results
    }

    // ── Individual rules ───────────────────────────────────────────────────

    private fun savings(current: List<TransactionEntity>, isEn: Boolean): BudgiInsight? {
        val income = current.filter { it.type == TransactionType.Income }.sumOf { it.amount }
        val expense = current.filter { it.type == TransactionType.Expense }.sumOf { it.amount }
        if (income <= 0) return null
        val savings = income - expense
        val positive = savings >= 0
        val text = if (positive) {
            if (isEn) "You saved ${money(savings)} from ${money(income)} income this month."
            else "Bu ay ${money(income)} gelirinden ${money(savings)} tasarruf ettin."
        } else {
            if (isEn) "Expenses exceeded income by ${money(-savings)} this month. Keep an eye on it."
            else "Bu ay giderlerin gelirini ${money(-savings)} aştı. Dikkat et."
        }
        val redacted = if (positive) {
            if (isEn) "You saved this month." else "Bu ay tasarruf ettin."
        } else {
            if (isEn) "Expenses exceeded income." else "Bu ay giderlerin gelirini aştı."
        }
        return BudgiInsight(
            tag = if (positive) (if (isEn) "SAVING" else "TASARRUF") else (if (isEn) "OVER BUDGET" else "AÇIK"),
            accent = if (positive) BudgiInsight.Accent.Income else BudgiInsight.Accent.Expense,
            text = text,
            redactedText = redacted,
        )
    }

    private fun topCategory(
        current: List<TransactionEntity>,
        categories: List<CategoryEntity>,
        isEn: Boolean,
    ): BudgiInsight? {
        val expenses = current.filter { it.type == TransactionType.Expense && it.categoryId != null }
        if (expenses.isEmpty()) return null
        val byCategory = expenses.groupBy { it.categoryId!! }.mapValues { it.value.sumOf { tx -> tx.amount } }
        val (topId, topAmount) = byCategory.maxByOrNull { it.value } ?: return null
        val cat = categories.firstOrNull { it.id == topId } ?: return null
        val total = expenses.sumOf { it.amount }
        val pct = if (total > 0) (topAmount.toDouble() / total * 100).toInt() else 0
        return BudgiInsight(
            tag = if (isEn) "TOP CATEGORY" else "EN YÜKSEK KATEGORİ",
            accent = BudgiInsight.Accent.Primary,
            text = if (isEn)
                "${cat.name} is the top expense this month: ${money(topAmount)} ($pct% of total spending)."
            else
                "${cat.name} bu ayın en büyük gider kalemi: ${money(topAmount)} (toplam giderlerin %$pct'i).",
            redactedText = if (isEn)
                "${cat.name} is the top expense ($pct%)."
            else
                "${cat.name} bu ayın en büyük gider kalemi (%$pct).",
        )
    }

    private fun monthOverMonth(
        current: List<TransactionEntity>,
        previous: List<TransactionEntity>,
        isEn: Boolean,
    ): BudgiInsight? {
        val cur = current.filter { it.type == TransactionType.Expense }.sumOf { it.amount }
        val prv = previous.filter { it.type == TransactionType.Expense }.sumOf { it.amount }
        if (prv <= 0) return null
        val pct = (cur - prv).toDouble() / prv * 100
        if (abs(pct) < 5) return null
        val up = pct > 0
        return BudgiInsight(
            tag = if (up) (if (isEn) "SPIKE" else "ANOMALİ") else (if (isEn) "DROP" else "AZALIŞ"),
            accent = if (up) BudgiInsight.Accent.Expense else BudgiInsight.Accent.Income,
            text = if (isEn)
                "${money(cur)} → last month ${money(prv)}. Spending ${if (up) "increased" else "decreased"} ${"%.0f".format(abs(pct))}% this month."
            else
                "${money(cur)} → geçen ${money(prv)}. Bu ay giderlerin %${"%.0f".format(abs(pct))} ${if (up) "arttı" else "azaldı"}.",
            redactedText = if (isEn)
                "Spending ${if (up) "increased" else "decreased"} ${"%.0f".format(abs(pct))}% this month."
            else
                "Bu ay giderlerin %${"%.0f".format(abs(pct))} ${if (up) "arttı" else "azaldı"}.",
        )
    }

    private fun biggestExpense(current: List<TransactionEntity>, isEn: Boolean): BudgiInsight? {
        val big = current.filter { it.type == TransactionType.Expense }.maxByOrNull { it.amount } ?: return null
        val label = big.note.ifBlank { if (isEn) "Untitled" else "İsimsiz" }
        return BudgiInsight(
            tag = if (isEn) "BIGGEST" else "EN BÜYÜK İŞLEM",
            accent = BudgiInsight.Accent.Warning,
            text = if (isEn) "Biggest expense this month: \"$label\" — ${money(big.amount)}."
            else "Bu ayın en büyük gideri: \"$label\" — ${money(big.amount)}.",
            redactedText = if (isEn) "Biggest expense this month: \"$label\" — ••••."
            else "Bu ayın en büyük gideri: \"$label\" — ••••.",
        )
    }

    private fun dailyAverage(
        current: List<TransactionEntity>,
        zone: ZoneId,
        isEn: Boolean,
    ): BudgiInsight? {
        val expenses = current.filter { it.type == TransactionType.Expense }
        if (expenses.isEmpty()) return null
        val total = expenses.sumOf { it.amount }
        val now = java.time.LocalDate.now(zone)
        val monthStart = YearMonth.from(now).atDay(1)
        val daysElapsed = (ChronoUnit.DAYS.between(monthStart, now) + 1).coerceAtLeast(1)
        val dailyAvg = total / daysElapsed
        val daysInMonth = YearMonth.from(now).lengthOfMonth().toLong()
        val projected = dailyAvg * daysInMonth

        return BudgiInsight(
            tag = if (isEn) "PACE" else "ÖNERİ",
            accent = BudgiInsight.Accent.Info,
            text = if (isEn)
                "Your daily average spending is ${money(dailyAvg)}. At this pace, end-of-month estimate: ${money(projected)}."
            else
                "Günlük ortalama harcaman ${money(dailyAvg)}. Bu hızla ay sonu tahmini: ${money(projected)}.",
            redactedText = if (isEn)
                "Your daily spending average has been calculated."
            else
                "Günlük ortalama harcaman hesaplandı.",
        )
    }

    private fun money(minor: Long): String =
        "₺" + "%,.2f".format(Money(minor).toBigDecimal())
}
