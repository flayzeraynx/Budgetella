//
//  Spacing.swift
//  Budgetella
//
//  Tasarım scale: 4 / 8 / 12 / 16 / 24 / 32 (px). 4'ün katları.
//  Border radius: 8 small / 16 medium / 28 sheet (bottom sheets, paywall modal).
//
//  Bu sabit'ler magic number'ları engellemek için heryerde kullanılmalı:
//    .padding(Spacing.md)             // 16
//    .padding(.horizontal, Spacing.lg) // 24
//    RoundedRectangle(cornerRadius: Spacing.radiusSheet)  // 28
//

import CoreGraphics

public enum Spacing {

    // ── Spacing scale
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 48

    // ── Border radius scale
    public static let radiusSmall: CGFloat = 8
    public static let radiusMedium: CGFloat = 16
    public static let radiusLarge: CGFloat = 24
    public static let radiusSheet: CGFloat = 28
    public static let radiusFull: CGFloat = 999  // pill

    // ── Hit target (a11y minimum)
    public static let minTouchTarget: CGFloat = 44

    // ── Container widths (responsive limit'ler)
    public static let maxContentWidth: CGFloat = 480
    public static let maxFormWidth: CGFloat = 360
}
