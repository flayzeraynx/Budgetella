package com.budgetella.app.core.design

import androidx.compose.ui.unit.dp

/**
 * 4 / 8 / 12 / 16 / 24 / 32 dp scale — exact port of iOS Spacing.swift.
 * Use these everywhere instead of magic numbers.
 */
object Spacing {

    // Scale
    val xs = 4.dp
    val sm = 8.dp
    val md = 12.dp
    val lg = 16.dp
    val xl = 24.dp
    val xxl = 32.dp
    val xxxl = 48.dp

    // Radii
    val radiusSmall = 8.dp
    val radiusMedium = 16.dp
    val radiusLarge = 24.dp
    val radiusSheet = 28.dp
    val radiusFull = 999.dp  // pill

    // A11y minimum touch target
    val minTouchTarget = 44.dp

    // Container width caps
    val maxContentWidth = 480.dp
    val maxFormWidth = 360.dp
}
