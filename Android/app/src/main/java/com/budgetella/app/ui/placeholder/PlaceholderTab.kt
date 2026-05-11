package com.budgetella.app.ui.placeholder

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import com.budgetella.app.ui.main.AppTab

/**
 * Stand-in tab content. Each milestone replaces one of these:
 *   Home   → DashboardScreen      (cards, charts, hero card)
 *   List   → TransactionsScreen   (year/month/day grouping)
 *   Stats  → StatsScreen          (donut + bar + AI card)
 *   Ai     → BudgiScreen          (chat with Gemini)
 */
@Composable
fun PlaceholderTab(tab: AppTab) {
    val (placeholderRes, accent) = when (tab) {
        AppTab.Home  -> R.string.placeholder_home  to BrandColor.Primary
        AppTab.List  -> R.string.placeholder_list  to BrandColor.Info
        AppTab.Stats -> R.string.placeholder_stats to BrandColor.Income
        AppTab.Ai    -> R.string.placeholder_ai    to BrandColor.PrimaryLight
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BrandColor.background())
            .statusBarsPadding()
            .padding(Spacing.xl),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.lg),
        ) {
            Box(
                modifier = Modifier
                    .size(72.dp)
                    .clip(CircleShape)
                    .background(accent.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = tab.icon,
                    contentDescription = null,
                    tint = accent,
                    modifier = Modifier.size(32.dp)
                )
            }

            Text(
                text = stringResource(tab.labelRes),
                style = BrandText.title,
                color = BrandColor.textPrimary(),
                textAlign = TextAlign.Center,
            )
            Text(
                text = stringResource(placeholderRes),
                style = BrandText.body,
                color = BrandColor.textTertiary(),
                textAlign = TextAlign.Center,
            )
        }
    }
}
