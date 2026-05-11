package com.budgetella.app.data.model

import java.math.BigDecimal
import java.math.RoundingMode

/**
 * Money type — amounts are persisted as Long minor-units (kuruş for TRY, cents
 * for USD/EUR/GBP). 1 ₺ = 100 kuruş; 1 $ = 100 cents. Avoids the floating-point
 * drift you'd get from storing amounts as Double, and matches the precision
 * iOS gets out of Decimal.
 *
 * - To store: `Money.fromMajor(BigDecimal("12.50")).minorUnits` → 1250
 * - To display: `Money(1250L).toBigDecimal()` → 12.50
 *
 * Currency is tracked separately (on Transaction.currency), so this type is
 * just the numeric value.
 */
@JvmInline
value class Money(val minorUnits: Long) : Comparable<Money> {

    fun toBigDecimal(): BigDecimal =
        BigDecimal.valueOf(minorUnits, FRACTION_DIGITS)

    operator fun plus(other: Money): Money = Money(minorUnits + other.minorUnits)
    operator fun minus(other: Money): Money = Money(minorUnits - other.minorUnits)
    operator fun unaryMinus(): Money = Money(-minorUnits)

    override fun compareTo(other: Money): Int = minorUnits.compareTo(other.minorUnits)

    val isPositive: Boolean get() = minorUnits > 0
    val isNegative: Boolean get() = minorUnits < 0
    val isZero: Boolean     get() = minorUnits == 0L

    companion object {
        const val FRACTION_DIGITS: Int = 2
        val Zero: Money = Money(0)

        /** Major-unit (e.g. "12.50") → Money. Rounds half-up at 2 decimals. */
        fun fromMajor(value: BigDecimal): Money =
            Money(
                value
                    .setScale(FRACTION_DIGITS, RoundingMode.HALF_UP)
                    .movePointRight(FRACTION_DIGITS)
                    .toLong()
            )

        fun fromMajor(value: Double): Money =
            fromMajor(BigDecimal.valueOf(value))

        /** Parse user input strings ("12,50" or "12.50"). Returns null on garbage. */
        fun parseMajorOrNull(input: String): Money? {
            val cleaned = input.trim().replace(',', '.').replace("\\s".toRegex(), "")
            return runCatching { fromMajor(BigDecimal(cleaned)) }.getOrNull()
        }
    }
}
