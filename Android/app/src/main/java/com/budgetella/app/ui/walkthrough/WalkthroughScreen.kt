package com.budgetella.app.ui.walkthrough

import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.Adjust
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material3.Button
import androidx.compose.runtime.getValue
import com.airbnb.lottie.compose.LottieAnimation
import com.airbnb.lottie.compose.LottieCompositionSpec
import com.airbnb.lottie.compose.LottieConstants
import com.airbnb.lottie.compose.animateLottieCompositionAsState
import com.airbnb.lottie.compose.rememberLottieComposition
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import kotlinx.coroutines.launch

/**
 * v1.1.0 — post-auth feature tutorial. Shown once after first sign-in,
 * before MainScaffold. SpinDeck OnboardingScreen referans alındı.
 *
 * Lottie dep eklendi; her sayfa önce assets/walkthrough_*.json yüklemeye
 * çalışır, asset yoksa Material Icon fallback'ine düşer. JSON dosyaları
 * app/src/main/assets/ altına atılınca otomatik aktive olur.
 */
private data class WalkthroughPage(
    val icon: ImageVector,
    val iconColor: Color,
    val lottieAsset: String,
    val titleRes: Int,
    val bodyRes: Int,
)

@Composable
fun WalkthroughScreen(onFinish: () -> Unit) {
    val pages = listOf(
        WalkthroughPage(
            icon = Icons.Filled.AddCircle,
            iconColor = BrandColor.Primary,
            lottieAsset = "walkthrough_add.json",
            titleRes = R.string.walkthrough_add_title,
            bodyRes = R.string.walkthrough_add_body,
        ),
        WalkthroughPage(
            icon = Icons.Filled.PieChart,
            iconColor = BrandColor.Income,
            lottieAsset = "walkthrough_summary.json",
            titleRes = R.string.walkthrough_summary_title,
            bodyRes = R.string.walkthrough_summary_body,
        ),
        WalkthroughPage(
            icon = Icons.Filled.Adjust,
            iconColor = BrandColor.Warning,
            lottieAsset = "walkthrough_goal.json",
            titleRes = R.string.walkthrough_goal_title,
            bodyRes = R.string.walkthrough_goal_body,
        ),
    )

    val pagerState = rememberPagerState(pageCount = { pages.size })
    val scope = rememberCoroutineScope()
    val isLast = pagerState.currentPage == pages.size - 1

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BrandColor.background()),
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Skip button (top-right, hidden on last page)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = Spacing.sm, end = Spacing.lg),
                horizontalArrangement = Arrangement.End,
            ) {
                if (!isLast) {
                    TextButton(onClick = onFinish) {
                        Text(
                            text = stringResource(R.string.walkthrough_skip),
                            style = BrandText.subheadline,
                            color = BrandColor.textTertiary(),
                        )
                    }
                } else {
                    Spacer(Modifier.height(48.dp))
                }
            }

            HorizontalPager(
                state = pagerState,
                modifier = Modifier.weight(1f),
            ) { page ->
                PageContent(page = pages[page])
            }

            PageDots(
                count = pages.size,
                selected = pagerState.currentPage,
                modifier = Modifier
                    .align(Alignment.CenterHorizontally)
                    .padding(bottom = Spacing.sm),
            )

            Button(
                onClick = {
                    if (isLast) onFinish()
                    else scope.launch {
                        pagerState.animateScrollToPage(
                            pagerState.currentPage + 1,
                            animationSpec = tween(durationMillis = 260),
                        )
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.xl, vertical = Spacing.lg)
                    .height(54.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = BrandColor.Primary,
                    contentColor = Color.White,
                ),
            ) {
                Text(
                    text = stringResource(
                        if (isLast) R.string.walkthrough_get_started
                        else R.string.walkthrough_next
                    ),
                    style = BrandText.headline,
                )
            }
        }
    }
}

@Composable
private fun PageContent(page: WalkthroughPage) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Spacing.xl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Hero(page = page)
        Spacer(Modifier.height(Spacing.xl))
        Text(
            text = stringResource(page.titleRes),
            style = BrandText.largeTitle,
            color = BrandColor.textPrimary(),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(Spacing.md))
        Text(
            text = stringResource(page.bodyRes),
            style = BrandText.body,
            color = BrandColor.textSecondary(),
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = Spacing.md),
        )
    }
}

@Composable
private fun Hero(page: WalkthroughPage) {
    // Try the Lottie JSON first; if the asset isn't bundled yet, composition
    // stays null and we render the Material Icon fallback.
    val composition by rememberLottieComposition(
        LottieCompositionSpec.Asset(page.lottieAsset),
    )
    val progress by animateLottieCompositionAsState(
        composition = composition,
        iterations = LottieConstants.IterateForever,
    )

    if (composition != null) {
        LottieAnimation(
            composition = composition,
            progress = { progress },
            modifier = Modifier.size(220.dp),
        )
    } else {
        Box(
            modifier = Modifier
                .size(180.dp)
                .clip(CircleShape)
                .background(page.iconColor.copy(alpha = 0.14f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = page.icon,
                contentDescription = null,
                tint = page.iconColor,
                modifier = Modifier.size(80.dp),
            )
        }
    }
}

@Composable
private fun PageDots(count: Int, selected: Int, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        repeat(count) { i ->
            val isActive = i == selected
            Box(
                modifier = Modifier
                    .height(7.dp)
                    .width(if (isActive) 22.dp else 7.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(
                        if (isActive) BrandColor.Primary
                        else BrandColor.textTertiary().copy(alpha = 0.3f)
                    ),
            )
        }
    }
}
