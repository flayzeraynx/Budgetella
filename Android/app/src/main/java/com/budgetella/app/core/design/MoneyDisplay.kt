package com.budgetella.app.core.design

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import com.budgetella.app.data.model.AppCurrency
import com.budgetella.app.data.model.Money
import java.util.Locale

/**
 * Whether amounts should be redacted in the UI (Settings → Security →
 * Hide amounts). Provided by [AppRoot] from the user's AppSettings row;
 * defaults to `false` for orphan composables (previews, splash, etc.).
 *
 * Sites that render currency values (Dashboard hero, Stats donut total,
 * TransactionRow, …) read this and swap the digits for [HIDDEN_MASK]
 * without touching the underlying data layer.
 */
val LocalHideAmounts = staticCompositionLocalOf { false }

/**
 * Active display currency. AppRoot provides the user's AppSettings.currency
 * choice; anywhere that renders money picks the symbol up from this so the
 * picker actually takes effect (the underlying minor-unit values are stored
 * raw — only the visual prefix changes).
 */
val LocalCurrency = staticCompositionLocalOf { AppCurrency.Try }

/** Visual replacement when hideAmounts is on. Matches the iOS app's bullet mask. */
const val HIDDEN_MASK: String = "••••"

/**
 * Composable-aware money formatter. Drops decimals everywhere (the kuruş/cents
 * never made it into the design) and truncates large values to a compact
 * `1.2K`, `3.4M`, `1.1B` form so they fit in the dashboard tiles. Returns
 * [HIDDEN_MASK] when LocalHideAmounts is on.
 */
@Composable
@ReadOnlyComposable
fun moneyText(
    minorUnits: Long,
    currency: String? = null,
    @Suppress("UNUSED_PARAMETER") decimals: Int = 0,
): String = formatMoney(
    minorUnits = minorUnits,
    // Caller can pin a specific currency (e.g. transaction rows that carry
    // their own currency). When null we fall through to the user-selected
    // display currency.
    currency = currency ?: LocalCurrency.current.raw,
    hideAmounts = LocalHideAmounts.current,
)

/**
 * Plain, side-effect-free formatter — usable in ViewModels, mappers, and
 * non-composable contexts. Pass `hideAmounts = true` explicitly to mask.
 *
 * Numbers under 1,000 print as-is; everything bigger collapses to a single
 * decimal compact form (₺12,345 → ₺12.3K). Negative values get a leading
 * "−" so the symbol stays adjacent to the digits.
 */
fun formatMoney(
    minorUnits: Long,
    currency: String = "TRY",
    hideAmounts: Boolean = false,
): String {
    if (hideAmounts) return HIDDEN_MASK
    val symbol = currencySymbol(currency)
    val majorLong = Money(minorUnits).toBigDecimal().toLong()
    val sign = if (majorLong < 0) "−" else ""
    val absMajor = kotlin.math.abs(majorLong)
    // Match the iOS compactTRY ladder so values render the same precision
    // across platforms: 1.77M / 12.3K / 850. Suffix for thousands is locale
    // aware — Turkish abbreviates as "B" (Bin), English uses "K".
    val thousandSuffix = if (Locale.getDefault().language.equals("tr", ignoreCase = true)) "B" else "K"
    val body = when {
        absMajor < 1_000L           -> absMajor.toString()
        absMajor < 1_000_000L       -> "%.1f%s".format(absMajor.toDouble() / 1_000.0, thousandSuffix)
        absMajor < 1_000_000_000L   -> "%.2fM".format(absMajor.toDouble() / 1_000_000.0)
        else                        -> "%.2fB".format(absMajor.toDouble() / 1_000_000_000.0)
    }
    return "$sign$symbol$body"
}

fun currencySymbol(raw: String): String = when (raw.uppercase(Locale.ROOT)) {
    "TRY" -> "₺"
    "USD" -> "$"
    "EUR" -> "€"
    "GBP" -> "£"
    else -> raw
}
