package com.budgetella.app.ui.main

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing

/**
 * 5-slot bottom bar — Home / List / FAB(+) / Stats / AI.
 * Mirrors iOS CustomTabBar (FAB blob menu deferred to a later milestone —
 * tap just opens the quick-entry sheet for now).
 */
@Composable
fun BottomTabBar(
    tabs: List<AppTab>,
    selected: AppTab,
    onSelect: (AppTab) -> Unit,
    onFabClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Split the four tab pills around the center FAB.
    val first = remember(tabs) { tabs.take(2) }
    val last = remember(tabs) { tabs.takeLast(2) }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(BrandColor.background2().copy(alpha = 0.92f))
            .navigationBarsPadding()
            .height(72.dp)
            .padding(horizontal = Spacing.xs),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        first.forEach { tab ->
            TabPill(
                tab = tab,
                isSelected = tab == selected,
                onClick = { onSelect(tab) },
                modifier = Modifier.weight(1f)
            )
        }

        FabButton(
            onClick = onFabClick,
            modifier = Modifier
                .weight(1f)
                .offset(y = (-10).dp),
        )

        last.forEach { tab ->
            TabPill(
                tab = tab,
                isSelected = tab == selected,
                onClick = { onSelect(tab) },
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun FabButton(onClick: () -> Unit, modifier: Modifier = Modifier) {
    Box(modifier = modifier, contentAlignment = Alignment.Center) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .shadow(elevation = 12.dp, shape = CircleShape, ambientColor = BrandColor.Primary, spotColor = BrandColor.Primary)
                .clip(CircleShape)
                .background(
                    Brush.linearGradient(listOf(BrandColor.Primary, BrandColor.PrimaryLight))
                )
                .clickable(onClick = onClick),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = Icons.Filled.Add,
                contentDescription = "Add",
                tint = androidx.compose.ui.graphics.Color.White,
                modifier = Modifier.size(26.dp),
            )
        }
    }
}

@Composable
private fun TabPill(
    tab: AppTab,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val iconScale by animateFloatAsState(
        targetValue = if (isSelected) 1.05f else 1.0f,
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy),
        label = "tabIconScale"
    )
    val tint = if (isSelected) BrandColor.Primary else BrandColor.textTertiary()
    val interactionSource = remember { MutableInteractionSource() }

    Box(
        modifier = modifier
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                onClick = onClick
            )
            .padding(vertical = Spacing.xs),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Icon(
                imageVector = tab.icon,
                contentDescription = stringResource(tab.labelRes),
                tint = tint,
                modifier = Modifier
                    .size(22.dp)
                    .scale(iconScale)
            )
            Spacer(modifier = Modifier.height(3.dp))
            Text(
                text = stringResource(tab.labelRes),
                style = BrandText.caption,
                color = tint,
            )
        }
    }
}
