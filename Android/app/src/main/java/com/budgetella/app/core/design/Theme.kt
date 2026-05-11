package com.budgetella.app.core.design

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/**
 * Material3 theme wired to the brand tokens. Use as the outermost composable
 * in MainActivity:
 *
 *   setContent { BudgetellaTheme { AppRoot() } }
 *
 * Mirrors iOS's `preferredColorScheme(.dark)` default — the user can flip
 * to light or system from Settings later (mirrors AppTheme enum on iOS).
 */
@Composable
fun BudgetellaTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colors = if (darkTheme) BudgetellaDarkColors else BudgetellaLightColors

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            // Transparent status / nav bars so glass-card backgrounds extend
            // edge-to-edge — same look as iOS.
            window.statusBarColor = Color.Transparent.toArgb()
            window.navigationBarColor = Color.Transparent.toArgb()
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = !darkTheme
                isAppearanceLightNavigationBars = !darkTheme
            }
        }
    }

    MaterialTheme(
        colorScheme = colors,
        typography = BudgetellaTypography,
        content = content
    )
}

// ── Material3 color schemes derived from brand tokens ──────────────────────

private val BudgetellaDarkColors = darkColorScheme(
    primary       = BrandColor.Primary,
    onPrimary     = Color.White,
    primaryContainer = BrandColor.Primary.copy(alpha = 0.18f),
    onPrimaryContainer = Color.White,
    secondary     = BrandColor.PrimaryLight,
    onSecondary   = Color.White,
    tertiary      = BrandColor.Info,
    onTertiary    = Color.White,

    background    = Color(0xFF0A0B14),
    onBackground  = Color.White,
    surface       = Color(0xFF11141C),
    onSurface     = Color.White,
    surfaceVariant      = Color(0xFF1A1F2E),
    onSurfaceVariant    = Color.White.copy(alpha = 0.72f),
    outline             = Color.White.copy(alpha = 0.16f),
    outlineVariant      = Color.White.copy(alpha = 0.08f),

    error         = BrandColor.Expense,
    onError       = Color.White,
)

private val BudgetellaLightColors = lightColorScheme(
    primary       = BrandColor.Primary,
    onPrimary     = Color.White,
    primaryContainer = BrandColor.Primary.copy(alpha = 0.12f),
    onPrimaryContainer = Color(0xFF1A1B2E),
    secondary     = BrandColor.PrimaryLight,
    onSecondary   = Color.White,
    tertiary      = BrandColor.Info,
    onTertiary    = Color.White,

    background    = Color(0xFFF5F6FE),
    onBackground  = Color(0xFF1A1B2E),
    surface       = Color.White,
    onSurface     = Color(0xFF1A1B2E),
    surfaceVariant      = Color(0xFFF0F1FA),
    onSurfaceVariant    = Color(0xFF1A1B2E).copy(alpha = 0.72f),
    outline             = Color.Black.copy(alpha = 0.16f),
    outlineVariant      = Color.Black.copy(alpha = 0.08f),

    error         = BrandColor.Expense,
    onError       = Color.White,
)
