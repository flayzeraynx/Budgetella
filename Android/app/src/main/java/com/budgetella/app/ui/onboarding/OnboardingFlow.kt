package com.budgetella.app.ui.onboarding

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.DrawableRes
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import com.budgetella.app.ui.main.AppTab
import kotlinx.coroutines.launch

/**
 * Three-screen onboarding carousel — Welcome → Features → Permissions.
 * Mirrors the iOS OnboardingView count and intent; the iOS Currency screen
 * lives in Settings on Android (we already force English on first launch).
 */
@Composable
fun OnboardingFlow(onFinished: () -> Unit) {
    val pages = remember { listOf(OnboardingPage.Welcome, OnboardingPage.Features, OnboardingPage.Permissions) }
    val pagerState = rememberPagerState(pageCount = { pages.size })
    val scope = rememberCoroutineScope()
    val currentPage by remember { derivedStateOf { pagerState.currentPage } }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BrandColor.background())
            .statusBarsPadding()
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Top bar — brand mark + Skip (hidden on the last page).
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.lg, vertical = Spacing.md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = stringResource(R.string.app_name),
                    style = BrandText.subheadline,
                    color = BrandColor.textSecondary(),
                )
                Spacer(Modifier.weight(1f))
                AnimatedVisibility(
                    visible = currentPage < pages.lastIndex,
                    enter = fadeIn(),
                    exit = fadeOut(),
                ) {
                    TextButton(onClick = onFinished) {
                        Text(
                            text = stringResource(R.string.onboarding_skip),
                            color = BrandColor.textTertiary(),
                        )
                    }
                }
            }

            HorizontalPager(
                state = pagerState,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
            ) { index ->
                when (pages[index]) {
                    OnboardingPage.Welcome -> WelcomePage()
                    OnboardingPage.Features -> FeaturesPage()
                    OnboardingPage.Permissions -> PermissionsPage()
                }
            }

            // Bottom bar — pager dots + CTA.
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.xl, vertical = Spacing.lg)
                    .navigationBarsPadding(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(Spacing.md),
            ) {
                PagerDots(count = pages.size, current = currentPage)
                Button(
                    onClick = {
                        if (currentPage < pages.lastIndex) {
                            scope.launch { pagerState.animateScrollToPage(currentPage + 1) }
                        } else {
                            onFinished()
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(Spacing.radiusFull),
                    colors = ButtonDefaults.buttonColors(containerColor = BrandColor.Primary),
                ) {
                    Text(
                        text = stringResource(
                            if (currentPage < pages.lastIndex) R.string.onboarding_next
                            else R.string.onboarding_get_started
                        ),
                        style = BrandText.subheadline,
                    )
                }
            }
        }
    }
}

// ── Pages ──────────────────────────────────────────────────────────────────

@Composable
private fun WelcomePage() = OnboardingPageScaffold(
    icon = R.mipmap.ic_launcher_foreground,
    title = stringResource(R.string.onboarding_welcome_title),
    subtitle = stringResource(R.string.onboarding_welcome_subtitle),
)

@Composable
private fun FeaturesPage() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Spacing.xl),
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = stringResource(R.string.onboarding_features_title),
            style = BrandText.title,
            color = BrandColor.textPrimary(),
        )
        Spacer(Modifier.height(Spacing.sm))
        Text(
            text = stringResource(R.string.onboarding_features_subtitle),
            style = BrandText.body,
            color = BrandColor.textSecondary(),
        )
        Spacer(Modifier.height(Spacing.xl))

        FeatureRow(
            icon = AppTab.Home.icon,
            accent = BrandColor.Primary,
            title = stringResource(R.string.onboarding_feature_1_title),
            body = stringResource(R.string.onboarding_feature_1_body),
        )
        Spacer(Modifier.height(Spacing.md))
        FeatureRow(
            icon = AppTab.Stats.icon,
            accent = BrandColor.Income,
            title = stringResource(R.string.onboarding_feature_2_title),
            body = stringResource(R.string.onboarding_feature_2_body),
        )
        Spacer(Modifier.height(Spacing.md))
        FeatureRow(
            icon = AppTab.Ai.icon,
            accent = BrandColor.PrimaryLight,
            title = stringResource(R.string.onboarding_feature_3_title),
            body = stringResource(R.string.onboarding_feature_3_body),
        )
    }
}

@Composable
private fun PermissionsPage() {
    // POST_NOTIFICATIONS only exists from Android 13 (TIRAMISU). Below that
    // notifications are granted by manifest and we don't prompt.
    val notifLauncher = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        rememberLauncherForActivityResult(
            contract = ActivityResultContracts.RequestPermission(),
            onResult = { /* swallow — Settings can grant later */ }
        )
    } else null

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Spacing.xl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Box(
            modifier = Modifier
                .size(96.dp)
                .clip(CircleShape)
                .background(BrandColor.Primary.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = AppTab.Ai.icon,
                contentDescription = null,
                tint = BrandColor.Primary,
                modifier = Modifier.size(40.dp)
            )
        }
        Spacer(Modifier.height(Spacing.lg))
        Text(
            text = stringResource(R.string.onboarding_permissions_title),
            style = BrandText.title,
            color = BrandColor.textPrimary(),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(Spacing.sm))
        Text(
            text = stringResource(R.string.onboarding_permissions_subtitle),
            style = BrandText.body,
            color = BrandColor.textSecondary(),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(Spacing.xl))
        OutlinedButton(
            onClick = { notifLauncher?.launch(Manifest.permission.POST_NOTIFICATIONS) },
            shape = RoundedCornerShape(Spacing.radiusFull),
        ) {
            Text(
                text = stringResource(R.string.onboarding_permissions_notifications_label),
                style = BrandText.subheadline,
                color = BrandColor.Primary,
            )
        }
    }
}

// ── Helpers ────────────────────────────────────────────────────────────────

@Composable
private fun OnboardingPageScaffold(
    @DrawableRes icon: Int,
    title: String,
    subtitle: String,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Spacing.xl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Image(
            painter = painterResource(id = icon),
            contentDescription = null,
            modifier = Modifier.size(140.dp)
        )
        Spacer(Modifier.height(Spacing.xl))
        Text(
            text = title,
            style = BrandText.title,
            color = BrandColor.textPrimary(),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(Spacing.sm))
        Text(
            text = subtitle,
            style = BrandText.body,
            color = BrandColor.textSecondary(),
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun FeatureRow(
    icon: ImageVector,
    accent: Color,
    title: String,
    body: String,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.Top,
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(Spacing.radiusSmall))
                .background(accent.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = accent,
                modifier = Modifier.size(20.dp)
            )
        }
        Spacer(Modifier.width(Spacing.md))
        Column(modifier = Modifier.weight(1f)) {
            Text(text = title, style = BrandText.subheadline, color = BrandColor.textPrimary())
            Spacer(Modifier.height(2.dp))
            Text(text = body, style = BrandText.footnote, color = BrandColor.textTertiary())
        }
    }
}

@Composable
private fun PagerDots(count: Int, current: Int) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        repeat(count) { i ->
            val active = i == current
            Box(
                modifier = Modifier
                    .width(if (active) 20.dp else 6.dp)
                    .height(6.dp)
                    .clip(RoundedCornerShape(Spacing.radiusFull))
                    .background(
                        if (active) BrandColor.Primary
                        else BrandColor.textTertiary().copy(alpha = 0.4f)
                    )
            )
        }
    }
}

private enum class OnboardingPage { Welcome, Features, Permissions }
