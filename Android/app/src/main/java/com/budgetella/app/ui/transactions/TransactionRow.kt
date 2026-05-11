package com.budgetella.app.ui.transactions

import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.HomeWork
import androidx.compose.material.icons.filled.LocalCafe
import androidx.compose.material.icons.filled.LocalHospital
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.MovieFilter
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material.icons.filled.RequestQuote
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.Storefront
import androidx.compose.material.icons.filled.Tag
import androidx.compose.material.icons.filled.Wallet
import androidx.compose.material.icons.filled.Work
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.model.CategorySlug
import com.budgetella.app.data.model.Money
import com.budgetella.app.data.model.TransactionStatus
import com.budgetella.app.data.model.TransactionType
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Single transaction row — port of iOS TransactionRow.
 *
 * Tap → onClick (opens the edit sheet).
 * Long-press → onLongClick (delete confirmation in the parent).
 *
 * The slug-driven default icon mapping mirrors iOS CategorySlug.defaultIcon,
 * which used SF Symbols. The Material Icons we substitute here are visually
 * close — they'll be revisited once the design tokens for icons are unified.
 */
@Composable
fun TransactionRow(
    transaction: TransactionEntity,
    category: CategoryEntity?,
    onClick: () -> Unit,
    onLongClick: () -> Unit,
) {
    val type = transaction.type
    val amountColor = if (type == TransactionType.Income) BrandColor.Income else BrandColor.Expense
    val sign = if (type == TransactionType.Income) "+" else "-"
    val tint = category?.let { runCatching { Color(android.graphics.Color.parseColor(it.colorHex)) }.getOrNull() } ?: amountColor

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .combinedClickable(onClick = onClick, onLongClick = onLongClick)
            .padding(horizontal = Spacing.md, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        CategoryGlyph(category = category, tint = tint)

        Spacer(Modifier.width(Spacing.md))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = transaction.note.ifBlank { stringResource(R.string.transactions_unnamed) },
                style = BrandText.subheadline,
                color = BrandColor.textPrimary(),
                maxLines = 1,
            )
            Spacer(Modifier.size(2.dp))
            Row {
                if (category != null) {
                    Text(
                        text = category.name,
                        style = BrandText.caption,
                        color = BrandColor.textTertiary(),
                    )
                    Text(text = " · ", style = BrandText.caption, color = BrandColor.textTertiary())
                }
                Text(
                    text = formatTime(transaction.date),
                    style = BrandText.caption,
                    color = BrandColor.textTertiary(),
                )
            }
        }

        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = sign + formatAmount(transaction.amount, transaction.currency),
                style = BrandText.subheadline,
                color = amountColor,
                maxLines = 1,
            )
            if (transaction.status == TransactionStatus.Pending) {
                Text(
                    text = stringResource(R.string.transactions_pending),
                    style = BrandText.caption,
                    color = BrandColor.Warning,
                )
            }
        }
    }
}

@Composable
private fun CategoryGlyph(category: CategoryEntity?, tint: Color) {
    Box(
        modifier = Modifier
            .size(40.dp)
            .clip(CircleShape)
            .background(tint.copy(alpha = 0.15f)),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = category?.let { iconForSlug(CategorySlug.fromRaw(it.slug)) } ?: Icons.Filled.Tag,
            contentDescription = null,
            tint = tint,
            modifier = Modifier.size(20.dp),
        )
    }
}

// SF Symbol → Material Icon map. Best-effort visual match; not all symbols
// have perfect counterparts in Material Icons Extended, so we lean on the
// closest semantic equivalent.
internal fun iconForSlug(slug: CategorySlug?): ImageVector = when (slug) {
    CategorySlug.Salary       -> Icons.Filled.Wallet
    CategorySlug.Freelance    -> Icons.Filled.Work
    CategorySlug.Investments  -> Icons.Filled.PieChart
    CategorySlug.Gifts        -> Icons.Filled.CardGiftcard
    CategorySlug.ProductSale  -> Icons.Filled.Storefront
    CategorySlug.Loan         -> Icons.Filled.RequestQuote
    CategorySlug.Food         -> Icons.Filled.Restaurant
    CategorySlug.Transportation -> Icons.Filled.DirectionsCar
    CategorySlug.Housing      -> Icons.Filled.Home
    CategorySlug.Bills        -> Icons.Filled.Bolt
    CategorySlug.Healthcare   -> Icons.Filled.LocalHospital
    CategorySlug.Shopping     -> Icons.Filled.ShoppingBag
    CategorySlug.Entertainment -> Icons.Filled.MovieFilter
    CategorySlug.Education    -> Icons.Filled.Book
    CategorySlug.Other        -> Icons.Filled.MoreHoriz
    null                      -> Icons.Filled.Tag
}

internal fun formatAmount(minorUnits: Long, currency: String): String {
    val symbol = when (currency.uppercase(Locale.ROOT)) {
        "TRY" -> "₺"
        "USD" -> "$"
        "EUR" -> "€"
        "GBP" -> "£"
        else -> currency
    }
    val major = Money(minorUnits).toBigDecimal()
    return "$symbol${"%,.2f".format(major)}"
}

internal fun formatTime(epochMillis: Long): String =
    DateTimeFormatter.ofPattern("HH:mm")
        .withZone(ZoneId.systemDefault())
        .format(Instant.ofEpochMilli(epochMillis))

