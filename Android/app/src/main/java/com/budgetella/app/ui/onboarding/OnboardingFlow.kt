package com.budgetella.app.ui.onboarding

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.DrawableRes
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
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
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    // Three permissions, three trackers. Notifications only needs the runtime
    // ask on Android 13+; audio and camera need it on all supported versions.
    var notifGranted by remember { mutableStateOf(isNotifGranted(context)) }
    var micGranted by remember { mutableStateOf(isPermissionGranted(context, Manifest.permission.RECORD_AUDIO)) }
    var cameraGranted by remember { mutableStateOf(isPermissionGranted(context, Manifest.permission.CAMERA)) }

    var notifAttempted by remember { mutableStateOf(false) }
    var micAttempted by remember { mutableStateOf(false) }
    var cameraAttempted by remember { mutableStateOf(false) }

    // Refresh granted-state whenever the user comes back from Settings.
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                notifGranted = isNotifGranted(context)
                micGranted = isPermissionGranted(context, Manifest.permission.RECORD_AUDIO)
                cameraGranted = isPermissionGranted(context, Manifest.permission.CAMERA)
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    val notifLauncher = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        rememberLauncherForActivityResult(
            contract = ActivityResultContracts.RequestPermission(),
            onResult = { granted ->
                notifGranted = granted
                notifAttempted = true
            },
        )
    } else null

    val micLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
        onResult = { granted ->
            micGranted = granted
            micAttempted = true
        },
    )

    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
        onResult = { granted ->
            cameraGranted = granted
            cameraAttempted = true
        },
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Spacing.xl),
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = stringResource(R.string.onboarding_permissions_title),
            style = BrandText.title,
            color = BrandColor.textPrimary(),
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(Modifier.height(Spacing.sm))
        Text(
            text = stringResource(R.string.onboarding_permissions_subtitle),
            style = BrandText.body,
            color = BrandColor.textSecondary(),
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(Modifier.height(Spacing.xl))

        PermissionRow(
            icon = Icons.Filled.NotificationsActive,
            tint = BrandColor.Primary,
            title = stringResource(R.string.onboarding_permission_notifications_title),
            subtitle = stringResource(R.string.onboarding_permission_notifications_subtitle),
            granted = notifGranted,
            attempted = notifAttempted,
            onAllow = {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                    notifGranted = true
                } else {
                    notifLauncher?.launch(Manifest.permission.POST_NOTIFICATIONS)
                }
            },
            onOpenSettings = {
                val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                context.startActivity(intent)
            },
        )

        Spacer(Modifier.height(Spacing.md))

        PermissionRow(
            icon = Icons.Filled.Mic,
            tint = BrandColor.Income,
            title = stringResource(R.string.onboarding_permission_mic_title),
            subtitle = stringResource(R.string.onboarding_permission_mic_subtitle),
            granted = micGranted,
            attempted = micAttempted,
            onAllow = { micLauncher.launch(Manifest.permission.RECORD_AUDIO) },
            onOpenSettings = { openAppDetails(context) },
        )

        Spacer(Modifier.height(Spacing.md))

        PermissionRow(
            icon = Icons.Filled.CameraAlt,
            tint = BrandColor.Warning,
            title = stringResource(R.string.onboarding_permission_camera_title),
            subtitle = stringResource(R.string.onboarding_permission_camera_subtitle),
            granted = cameraGranted,
            attempted = cameraAttempted,
            onAllow = { cameraLauncher.launch(Manifest.permission.CAMERA) },
            onOpenSettings = { openAppDetails(context) },
        )

        Spacer(Modifier.height(Spacing.xl))

        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                imageVector = Icons.Filled.Fingerprint,
                contentDescription = null,
                tint = BrandColor.textTertiary(),
                modifier = Modifier.size(16.dp),
            )
            Spacer(Modifier.width(Spacing.sm))
            Text(
                text = stringResource(R.string.onboarding_permissions_biometric_hint),
                style = BrandText.footnote,
                color = BrandColor.textTertiary(),
            )
        }
    }
}

@Composable
private fun PermissionRow(
    icon: ImageVector,
    tint: androidx.compose.ui.graphics.Color,
    title: String,
    subtitle: String,
    granted: Boolean,
    attempted: Boolean,
    onAllow: () -> Unit,
    onOpenSettings: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(BrandColor.surface().copy(alpha = 0.4f))
            .padding(Spacing.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(tint.copy(alpha = 0.18f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = tint, modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.width(Spacing.md))
        Column(modifier = Modifier.weight(1f)) {
            Text(text = title, style = BrandText.subheadline, color = BrandColor.textPrimary())
            Text(text = subtitle, style = BrandText.caption, color = BrandColor.textTertiary())
        }
        Spacer(Modifier.width(Spacing.sm))
        if (granted) {
            Icon(
                imageVector = Icons.Filled.CheckCircle,
                contentDescription = null,
                tint = BrandColor.Income,
                modifier = Modifier.size(24.dp),
            )
        } else {
            OutlinedButton(
                onClick = if (attempted) onOpenSettings else onAllow,
                shape = RoundedCornerShape(Spacing.radiusFull),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(
                    horizontal = Spacing.md, vertical = 6.dp,
                ),
            ) {
                Text(
                    text = stringResource(
                        if (attempted) R.string.onboarding_permission_open_settings_short
                        else R.string.onboarding_permission_allow
                    ),
                    style = BrandText.caption,
                    color = BrandColor.Primary,
                )
            }
        }
    }
}

private fun openAppDetails(context: android.content.Context) {
    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        .setData(android.net.Uri.fromParts("package", context.packageName, null))
    context.startActivity(intent)
}

private fun isNotifGranted(context: android.content.Context): Boolean =
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
        true
    } else {
        isPermissionGranted(context, Manifest.permission.POST_NOTIFICATIONS)
    }

private fun isPermissionGranted(context: android.content.Context, permission: String): Boolean =
    ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED

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
