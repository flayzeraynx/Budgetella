package com.budgetella.app.ui.paywall

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import kotlinx.coroutines.launch

/**
 * Premium upsell — full-screen modal styled after iOS PaywallView.
 *
 * Visual hierarchy (top → bottom):
 *  1. Close X (top-right) — onClose
 *  2. Hero block: gradient header, sparkle mark, title, subtitle
 *  3. Feature list (4 rows, check-marked)
 *  4. Monthly/Yearly toggle pills
 *  5. CTA + free-trial copy
 *  6. Restore purchases text button
 *
 * The CTA is wired to a [Snackbar] showing `paywall_unavailable` — Play Billing
 * isn't integrated yet (see SubscriptionRepository). When billing lands, swap
 * the snackbar trigger for a `subscriptionRepository.startPurchase(...)` call.
 */
@Composable
fun PaywallScreen(onClose: () -> Unit) {
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val unavailableMessage = stringResource(R.string.paywall_unavailable)
    var selectedPlan by remember { mutableStateOf(PaywallPlan.Yearly) }

    Scaffold(
        containerColor = BrandColor.background(),
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        PaywallBody(
            outerPadding = padding,
            selectedPlan = selectedPlan,
            onSelectPlan = { selectedPlan = it },
            onClose = onClose,
            onPurchaseClick = {
                scope.launch { snackbarHostState.showSnackbar(unavailableMessage) }
            },
            onRestoreClick = {
                scope.launch { snackbarHostState.showSnackbar(unavailableMessage) }
            },
        )
    }
}

@Composable
private fun PaywallBody(
    outerPadding: PaddingValues,
    selectedPlan: PaywallPlan,
    onSelectPlan: (PaywallPlan) -> Unit,
    onClose: () -> Unit,
    onPurchaseClick: () -> Unit,
    onRestoreClick: () -> Unit,
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(outerPadding)
            .statusBarsPadding()
            .navigationBarsPadding(),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.lg),
        ) {
            CloseRow(onClose = onClose)
            Spacer(modifier = Modifier.height(Spacing.sm))
            Hero()
            Spacer(modifier = Modifier.height(Spacing.xl))
            FeatureList()
            Spacer(modifier = Modifier.height(Spacing.xl))
            PlanToggle(
                selected = selectedPlan,
                onSelect = onSelectPlan,
            )
            Spacer(modifier = Modifier.height(Spacing.lg))
            CtaBlock(
                plan = selectedPlan,
                onClick = onPurchaseClick,
            )
            Spacer(modifier = Modifier.height(Spacing.md))
            TextButton(
                onClick = onRestoreClick,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(
                    text = stringResource(R.string.paywall_restore),
                    style = BrandText.footnote,
                    color = BrandColor.textTertiary(),
                )
            }
            Spacer(modifier = Modifier.height(Spacing.xl))
        }
    }
}

@Composable
private fun CloseRow(onClose: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = Spacing.sm),
        horizontalArrangement = Arrangement.End,
    ) {
        IconButton(
            onClick = onClose,
            modifier = Modifier.size(40.dp),
        ) {
            Icon(
                imageVector = Icons.Filled.Close,
                contentDescription = stringResource(R.string.common_cancel),
                tint = BrandColor.textSecondary(),
            )
        }
    }
}

@Composable
private fun Hero() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusLarge))
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        BrandColor.Primary.copy(alpha = 0.32f),
                        BrandColor.PrimaryLight.copy(alpha = 0.12f),
                    )
                )
            )
            .padding(vertical = Spacing.xxl, horizontal = Spacing.lg),
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                modifier = Modifier
                    .size(72.dp)
                    .clip(CircleShape)
                    .background(BrandColor.Primary),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = Icons.Filled.AutoAwesome,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(36.dp),
                )
            }
            Spacer(modifier = Modifier.height(Spacing.lg))
            Text(
                text = stringResource(R.string.paywall_title),
                style = BrandText.title,
                color = BrandColor.textPrimary(),
                textAlign = TextAlign.Center,
            )
            Spacer(modifier = Modifier.height(Spacing.sm))
            Text(
                text = stringResource(R.string.paywall_subtitle),
                style = BrandText.body,
                color = BrandColor.textSecondary(),
                textAlign = TextAlign.Center,
            )
        }
    }
}

@Composable
private fun FeatureList() {
    val features = listOf(
        R.string.paywall_feature_1,
        R.string.paywall_feature_2,
        R.string.paywall_feature_3,
        R.string.paywall_feature_4,
    )
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(Spacing.md),
    ) {
        features.forEach { resId ->
            FeatureRow(label = stringResource(resId))
        }
    }
}

@Composable
private fun FeatureRow(label: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = Icons.Filled.CheckCircle,
            contentDescription = null,
            tint = BrandColor.Primary,
            modifier = Modifier.size(24.dp),
        )
        Spacer(modifier = Modifier.size(Spacing.md))
        Text(
            text = label,
            style = BrandText.body,
            color = BrandColor.textPrimary(),
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

@Composable
private fun PlanToggle(
    selected: PaywallPlan,
    onSelect: (PaywallPlan) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusFull))
            .background(BrandColor.surface())
            .padding(Spacing.xs),
        horizontalArrangement = Arrangement.spacedBy(Spacing.xs),
    ) {
        PlanPill(
            label = stringResource(R.string.paywall_monthly),
            isSelected = selected == PaywallPlan.Monthly,
            onClick = { onSelect(PaywallPlan.Monthly) },
            modifier = Modifier.weight(1f),
        )
        PlanPill(
            label = stringResource(R.string.paywall_yearly),
            isSelected = selected == PaywallPlan.Yearly,
            onClick = { onSelect(PaywallPlan.Yearly) },
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
private fun PlanPill(
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .height(44.dp)
            .clip(RoundedCornerShape(Spacing.radiusFull))
            .background(if (isSelected) BrandColor.Primary else Color.Transparent)
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.md),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            style = BrandText.subheadline,
            color = if (isSelected) Color.White else BrandColor.textSecondary(),
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun CtaBlock(plan: PaywallPlan, onClick: () -> Unit) {
    val priceLabel = when (plan) {
        PaywallPlan.Monthly -> MONTHLY_PRICE
        PaywallPlan.Yearly -> YEARLY_PRICE
    }

    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Button(
            onClick = onClick,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            shape = RoundedCornerShape(Spacing.radiusMedium),
            colors = ButtonDefaults.buttonColors(
                containerColor = BrandColor.Primary,
                contentColor = Color.White,
            ),
        ) {
            Text(
                text = stringResource(R.string.paywall_cta),
                style = BrandText.subheadline,
            )
        }
        Spacer(modifier = Modifier.height(Spacing.sm))
        Text(
            text = stringResource(R.string.paywall_free_trial, priceLabel),
            style = BrandText.footnote,
            color = BrandColor.textTertiary(),
            textAlign = TextAlign.Center,
        )
    }
}

private enum class PaywallPlan { Monthly, Yearly }

// Stub prices — final values pulled from Play Billing when M8.1 lands.
// Numbers here mirror the iOS USD tiers from CLAUDE.md ($4.99 / $39.99).
private const val MONTHLY_PRICE: String = "$4.99/mo"
private const val YEARLY_PRICE: String = "$39.99/yr"
