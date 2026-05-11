package com.budgetella.app.core.design

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.graphics.Color

/**
 * Brand palette — exact port of iOS BrandColor.swift.
 *
 * Dark-first design system; the iOS app defaults to dark mode and so does this
 * one. Theme-aware tokens are composables so they re-resolve when the user
 * flips themes at runtime (matches iOS UIColor(dynamicProvider:) behaviour).
 *
 * Static tokens (primary, income, expense, …) are mode-independent — they
 * read the same in both themes by design.
 */
object BrandColor {

    // Mode-independent accents
    val Primary: Color = Color(0xFF6E5BFF)
    val PrimaryLight: Color = Color(0xFF8B6FFF)

    // Semantic financial — same in both modes
    val Income: Color = Color(0xFF10F2A5)
    val Expense: Color = Color(0xFFFB7185)
    val Warning: Color = Color(0xFFF59E0B)
    val Info: Color = Color(0xFF06B6D4)

    // ── Theme-aware tokens (composables) ────────────────────────────────────

    @Composable @ReadOnlyComposable
    fun background(): Color =
        if (isSystemInDarkTheme()) Color(0xFF0A0B14) else Color(0xFFF5F6FE)

    @Composable @ReadOnlyComposable
    fun background2(): Color =
        if (isSystemInDarkTheme()) Color(0xFF14152A) else Color(0xFFECEEF9)

    @Composable @ReadOnlyComposable
    fun background3(): Color =
        if (isSystemInDarkTheme()) Color(0xFF1A1740) else Color(0xFFE4E5F4)

    @Composable @ReadOnlyComposable
    fun surface(): Color =
        if (isSystemInDarkTheme()) Color(0xFF11141C) else Color(0xFFFFFFFF)

    @Composable @ReadOnlyComposable
    fun surfaceElevated(): Color =
        if (isSystemInDarkTheme()) Color(0xFF1A1F2E) else Color(0xFFF0F1FA)

    @Composable @ReadOnlyComposable
    fun textPrimary(): Color =
        if (isSystemInDarkTheme()) Color.White else Color(0xFF1A1B2E)

    @Composable @ReadOnlyComposable
    fun textSecondary(): Color =
        if (isSystemInDarkTheme()) Color.White.copy(alpha = 0.72f) else Color(0xFF1A1B2E).copy(alpha = 0.72f)

    @Composable @ReadOnlyComposable
    fun textTertiary(): Color =
        if (isSystemInDarkTheme()) Color.White.copy(alpha = 0.50f) else Color(0xFF1A1B2E).copy(alpha = 0.50f)

    @Composable @ReadOnlyComposable
    fun borderSubtle(): Color =
        if (isSystemInDarkTheme()) Color.White.copy(alpha = 0.08f) else Color.Black.copy(alpha = 0.08f)

    @Composable @ReadOnlyComposable
    fun borderMedium(): Color =
        if (isSystemInDarkTheme()) Color.White.copy(alpha = 0.16f) else Color.Black.copy(alpha = 0.16f)
}
