package com.budgetella.app.ui.paywall

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing

/**
 * Premium upsell — full-screen modal styled after iOS PaywallView.
 *
 * Wired to [PaywallViewModel] which owns Play Billing state. Prices come
 * straight from `ProductDetails.formattedPrice` so they localize automatically
 * (TR Play accounts see ₺, US accounts see $, etc.). No hard-coded prices.
 *
 * The CTA closes the sheet as soon as Firestore confirms an active entitlement.
 */
@Composable
fun PaywallScreen(
    onClose: () -> Unit,
    viewModel: PaywallViewModel = hiltViewModel(),
) {
    val snackbarHostState = remember { SnackbarHostState() }
    val context = LocalContext.current
    val activity = context as? Activity

    val selectedPlan by viewModel.selectedPlan.collectAsStateWithLifecycle()
    val purchaseState by viewModel.purchaseState.collectAsStateWithLifecycle()
    val isPremium by viewModel.isPremium.collectAsStateWithLifecycle()
    val products by viewModel.products.collectAsStateWithLifecycle()

    // Close the paywall as soon as the user is premium — covers both the
    // happy path (purchase succeeded) and restore-purchases.
    LaunchedEffect(isPremium) {
        if (isPremium) onClose()
    }

    Scaffold(
        containerColor = BrandColor.background(),
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        PaywallBody(
            outerPadding = padding,
            selectedPlan = selectedPlan,
            isPurchasing = purchaseState is PurchaseState.Loading,
            priceFor = { plan -> viewModel.formattedPrice(plan) },
            hasProducts = products.isNotEmpty(),
            onSelectPlan = viewModel::selectPlan,
            onClose = onClose,
            onPurchaseClick = {
                activity?.let(viewModel::startPurchase)
            },
            onRestoreClick = viewModel::restorePurchases,
        )

        if (purchaseState is PurchaseState.Error) {
            val message = (purchaseState as PurchaseState.Error).message
            AlertDialog(
                onDismissRequest = viewModel::acknowledgeError,
                title = { Text(stringResource(R.string.paywall_error_title)) },
                text = { Text(message) },
                confirmButton = {
                    TextButton(onClick = viewModel::acknowledgeError) {
                        Text(stringResource(R.string.common_ok))
                    }
                },
            )
        }
    }
}

@Composable
private fun PaywallBody(
    outerPadding: PaddingValues,
    selectedPlan: PaywallPlan,
    isPurchasing: Boolean,
    priceFor: (PaywallPlan) -> String?,
    hasProducts: Boolean,
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
            PlanCards(
                selected = selectedPlan,
                priceFor = priceFor,
                onSelect = onSelectPlan,
            )
            Spacer(modifier = Modifier.height(Spacing.lg))
            CtaBlock(
                plan = selectedPlan,
                priceFor = priceFor,
                isPurchasing = isPurchasing,
                enabled = hasProducts && !isPurchasing,
                onClick = onPurchaseClick,
            )
            Spacer(modifier = Modifier.height(Spacing.md))
            TextButton(
                onClick = onRestoreClick,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isPurchasing,
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
private fun PlanCards(
    selected: PaywallPlan,
    priceFor: (PaywallPlan) -> String?,
    onSelect: (PaywallPlan) -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(Spacing.sm),
    ) {
        PlanCard(
            plan = PaywallPlan.Monthly,
            title = stringResource(R.string.paywall_monthly_title),
            subtitle = null,
            price = priceFor(PaywallPlan.Monthly),
            period = stringResource(R.string.paywall_per_month),
            badge = null,
            isSelected = selected == PaywallPlan.Monthly,
            onClick = { onSelect(PaywallPlan.Monthly) },
        )
        PlanCard(
            plan = PaywallPlan.Yearly,
            title = stringResource(R.string.paywall_yearly_title),
            subtitle = null,
            price = priceFor(PaywallPlan.Yearly),
            period = stringResource(R.string.paywall_per_year),
            badge = stringResource(R.string.paywall_save_badge),
            isSelected = selected == PaywallPlan.Yearly,
            onClick = { onSelect(PaywallPlan.Yearly) },
        )
        PlanCard(
            plan = PaywallPlan.Lifetime,
            title = stringResource(R.string.paywall_lifetime_title),
            subtitle = stringResource(R.string.paywall_lifetime_subtitle),
            price = priceFor(PaywallPlan.Lifetime),
            period = null,
            badge = stringResource(R.string.paywall_lifetime_badge),
            isSelected = selected == PaywallPlan.Lifetime,
            onClick = { onSelect(PaywallPlan.Lifetime) },
        )
    }
}

@Composable
private fun PlanCard(
    plan: PaywallPlan,
    title: String,
    subtitle: String?,
    price: String?,
    period: String?,
    badge: String?,
    isSelected: Boolean,
    onClick: () -> Unit,
) {
    val borderColor = if (isSelected) BrandColor.Primary else BrandColor.surface()
    val backgroundColor = if (isSelected) {
        BrandColor.Primary.copy(alpha = 0.10f)
    } else {
        BrandColor.surface()
    }
    val accent = if (plan == PaywallPlan.Lifetime) BrandColor.Primary else BrandColor.PrimaryLight

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(backgroundColor)
            .border(
                width = if (isSelected) 2.dp else 1.dp,
                color = borderColor,
                shape = RoundedCornerShape(Spacing.radiusMedium),
            )
            .clickable(onClick = onClick)
            .padding(Spacing.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // Radio
        Box(
            modifier = Modifier
                .size(22.dp)
                .clip(CircleShape)
                .border(2.dp, if (isSelected) BrandColor.Primary else BrandColor.textTertiary(), CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            if (isSelected) {
                Box(
                    modifier = Modifier
                        .size(12.dp)
                        .clip(CircleShape)
                        .background(BrandColor.Primary)
                )
            }
        }
        Spacer(modifier = Modifier.width(Spacing.md))

        // Title + subtitle + badge
        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = title,
                    style = BrandText.subheadline,
                    color = BrandColor.textPrimary(),
                )
                if (badge != null) {
                    Spacer(modifier = Modifier.width(Spacing.xs))
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(Spacing.radiusFull))
                            .background(accent)
                            .padding(horizontal = 6.dp, vertical = 2.dp),
                    ) {
                        Text(
                            text = badge,
                            style = BrandText.caption,
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                }
            }
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = BrandText.caption,
                    color = BrandColor.textTertiary(),
                )
            }
        }

        // Price
        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = price ?: "—",
                style = BrandText.headline,
                color = if (isSelected) BrandColor.Primary else BrandColor.textPrimary(),
            )
            if (period != null) {
                Text(
                    text = period,
                    style = BrandText.caption,
                    color = BrandColor.textTertiary(),
                )
            }
        }
    }
}

@Composable
private fun CtaBlock(
    plan: PaywallPlan,
    priceFor: (PaywallPlan) -> String?,
    isPurchasing: Boolean,
    enabled: Boolean,
    onClick: () -> Unit,
) {
    val ctaLabel = when (plan) {
        PaywallPlan.Monthly, PaywallPlan.Yearly -> stringResource(R.string.paywall_cta_trial)
        PaywallPlan.Lifetime -> stringResource(R.string.paywall_cta_buy_now)
    }

    val finePrint = when (plan) {
        PaywallPlan.Monthly, PaywallPlan.Yearly ->
            priceFor(plan)?.let { stringResource(R.string.paywall_free_trial, it) }
                ?: stringResource(R.string.paywall_free_trial_generic)
        PaywallPlan.Lifetime -> stringResource(R.string.paywall_lifetime_finePrint)
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
            enabled = enabled,
        ) {
            if (isPurchasing) {
                CircularProgressIndicator(
                    color = Color.White,
                    strokeWidth = 2.dp,
                    modifier = Modifier.size(20.dp),
                )
            } else {
                Text(text = ctaLabel, style = BrandText.subheadline)
            }
        }
        Spacer(modifier = Modifier.height(Spacing.sm))
        Text(
            text = finePrint,
            style = BrandText.footnote,
            color = BrandColor.textTertiary(),
            textAlign = TextAlign.Center,
        )
    }
}
