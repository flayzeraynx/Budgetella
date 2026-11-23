package com.budgetella.app.ui.paywall

import androidx.annotation.StringRes
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText

/**
 * Single source of truth for what Premium unlocks on Android. The paywall
 * benefit list is rendered from this enum, so it cannot advertise something
 * that isn't locked. Mirrors iOS `PremiumFeature` minus the home-screen
 * widget, which Android does not ship.
 */
enum class PremiumFeature(@StringRes val title: Int, @StringRes val subtitle: Int) {
    Budgi(R.string.premium_feature_budgi, R.string.premium_feature_budgi_sub),
    ReceiptScan(R.string.premium_feature_receipt, R.string.premium_feature_receipt_sub),
    CustomCategories(R.string.premium_feature_categories, R.string.premium_feature_categories_sub),
}

/**
 * The paywall is offered unprompted at most twice: once on first arrival at
 * the main screen after onboarding, once after the 10th saved transaction.
 */
enum class PaywallPrompt {
    AfterOnboarding, AfterTenthTransaction;

    companion object {
        const val TRANSACTION_THRESHOLD = 10

        /** Pure decision — which proactive paywall (if any) is due right now. */
        fun next(
            isPremium: Boolean,
            onboardingDone: Boolean,
            shownOnboarding: Boolean,
            txCount: Int,
            shownAt10: Boolean,
        ): PaywallPrompt? = when {
            isPremium || !onboardingDone -> null
            !shownOnboarding -> AfterOnboarding
            txCount >= TRANSACTION_THRESHOLD && !shownAt10 -> AfterTenthTransaction
            else -> null
        }
    }
}

/** Small "Premium" pill for locked entry points — a gate should read as intentional. */
@Composable
fun PremiumBadge(modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(50))
            .background(BrandColor.Primary.copy(alpha = 0.15f))
            .padding(horizontal = 6.dp, vertical = 3.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = Icons.Filled.Lock,
            contentDescription = stringResource(R.string.premium_locked_cd),
            tint = BrandColor.Primary,
            modifier = Modifier.size(10.dp),
        )
        Spacer(Modifier.width(3.dp))
        Text(
            text = stringResource(R.string.settings_premium_label),
            style = BrandText.caption2,
            color = BrandColor.Primary,
            fontWeight = FontWeight.Bold,
        )
    }
}
