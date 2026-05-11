package com.budgetella.app.core.design

import androidx.compose.material3.Typography
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.unit.sp
import androidx.compose.ui.unit.em

/**
 * Brand typography — port of iOS BrandFont.swift.
 *
 * Inter is the design font on iOS but falls back to the system font there too,
 * so we use FontFamily.Default (Roboto on Android) until Inter ttfs are added
 * to res/font/. To swap in Inter later, change `brandFontFamily` to a
 * FontFamily(Font(R.font.inter_regular), …, …).
 */
private val brandFontFamily: FontFamily = FontFamily.Default

private fun brand(
    sizeSp: Int,
    weight: FontWeight,
    trackingEm: Float = 0f,
    monospacedDigit: Boolean = false
): TextStyle = TextStyle(
    fontFamily = brandFontFamily,
    fontSize = sizeSp.sp,
    fontWeight = weight,
    letterSpacing = trackingEm.em,
    fontFeatureSettings = if (monospacedDigit) "tnum" else null,
    platformStyle = PlatformTextStyle(includeFontPadding = false),
    lineHeightStyle = LineHeightStyle(
        alignment = LineHeightStyle.Alignment.Center,
        trim = LineHeightStyle.Trim.None
    )
)

/**
 * Direct text-style accessors — `BrandText.body`, `BrandText.title`, … —
 * mirroring the iOS `Font.brand(.body)` / `Font.brand(.title)` API.
 *
 * Trackings expressed in em (1 em = current font size). iOS's points-tracking
 * converts: trackingEm ≈ trackingPoints / sizePoints.
 */
object BrandText {

    // Hero / display
    val display      = brand(sizeSp = 56, weight = FontWeight.Bold, trackingEm = -0.027f)         // -1.5 / 56
    val displayHero  = brand(sizeSp = 38, weight = FontWeight.Bold, trackingEm = -0.021f, monospacedDigit = true)
    val largeTitle   = brand(sizeSp = 36, weight = FontWeight.Bold, trackingEm = -0.022f)
    val title        = brand(sizeSp = 28, weight = FontWeight.SemiBold, trackingEm = -0.014f)

    // Sections + body
    val headline     = brand(sizeSp = 20, weight = FontWeight.SemiBold)
    val subheadline  = brand(sizeSp = 17, weight = FontWeight.SemiBold)
    val body         = brand(sizeSp = 16, weight = FontWeight.Normal)
    val callout      = brand(sizeSp = 15, weight = FontWeight.Normal)

    // Helpers
    val footnote     = brand(sizeSp = 13, weight = FontWeight.Normal)
    val caption      = brand(sizeSp = 12, weight = FontWeight.Medium)
    val caption2     = brand(sizeSp = 11, weight = FontWeight.SemiBold, trackingEm = 0.045f)
}

/** Material3 [Typography] mapped from brand tokens — used as MaterialTheme.typography fallback. */
internal val BudgetellaTypography: Typography = Typography(
    displayLarge   = BrandText.display,
    displayMedium  = BrandText.displayHero,
    displaySmall   = BrandText.largeTitle,
    headlineLarge  = BrandText.title,
    headlineMedium = BrandText.title,
    headlineSmall  = BrandText.headline,
    titleLarge     = BrandText.title,
    titleMedium    = BrandText.headline,
    titleSmall     = BrandText.subheadline,
    bodyLarge      = BrandText.body,
    bodyMedium     = BrandText.callout,
    bodySmall      = BrandText.footnote,
    labelLarge     = BrandText.subheadline,
    labelMedium    = BrandText.caption,
    labelSmall     = BrandText.caption2,
)
