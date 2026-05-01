//
//  Colors.swift
//  Budgetella
//
//  Tasarım dili: "koyu glass premium". Aksent #6E5BFF.
//  V1'de hem dark hem light theme destekleniyor (system follow default);
//  asset catalog "AccentColor" ve "Brand" color set'leri ile dynamic resolve.
//
//  Kullanım:
//    Color.brand.primary          → #6E5BFF (theme-aware tone'lar)
//    Color.brand.surface          → glass card background
//    Color.brand.income           → semantic gelir
//    Color.brand.expense          → semantic gider
//

import SwiftUI

public enum BrandColor {

    // ── Aksent
    /// Ana aksent rengi (#6E5BFF). Glass premium dilinin imzası.
    public static let primary = Color(hex: "#6E5BFF")
    /// Hafif gradient eşi (#8B6FFF) — primary ile birlikte gradient.
    public static let primaryLight = Color(hex: "#8B6FFF")

    // ── Yüzey & arkaplan (dark theme baseline)
    /// Ana arkaplan — derin gece-mavi.
    public static let background = Color(hex: "#0A0B14")
    /// İkincil arkaplan — katman 2.
    public static let background2 = Color(hex: "#14152A")
    /// Üçüncül arkaplan — katman 3 (deep accent tint).
    public static let background3 = Color(hex: "#1A1740")
    /// Glass card / sheet yüzeyi — biraz daha açık.
    public static let surface = Color(hex: "#11141C")
    /// Yükseltilmiş yüzey (modal, popover).
    public static let surfaceElevated = Color(hex: "#1A1F2E")

    // ── Metin
    public static let textPrimary = Color(hex: "#FFFFFF")
    public static let textSecondary = Color.white.opacity(0.72)
    public static let textTertiary = Color.white.opacity(0.50)

    // ── Border / divider
    public static let borderSubtle = Color.white.opacity(0.08)
    public static let borderMedium = Color.white.opacity(0.16)

    // ── Semantik finansal
    /// Gelir (teal glow). Income summary, positive amount.
    public static let income = Color(hex: "#10F2A5")
    /// Gider (soft pembe). Expense summary, negative amount.
    public static let expense = Color(hex: "#FB7185")
    /// Anomali / uyarı (turuncu).
    public static let warning = Color(hex: "#F59E0B")
    /// Bilgi (cyan).
    public static let info = Color(hex: "#06B6D4")
}

public extension Color {
    /// Brand color shortcut: `Color.brand.primary`.
    static let brand = BrandColor.self
}

// MARK: - Hex initializer

public extension Color {
    /// Hex string ile Color üret. "#RRGGBB" veya "RRGGBB" kabul eder.
    /// Geçersiz hex'te `Color.gray` döner — UI'da debug için belirgin kalır.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard cleaned.count == 6,
              let value = UInt64(cleaned, radix: 16) else {
            self = .gray
            return
        }

        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Glass material

/// Tasarım dilinin imzası: blur + subtle border + depth.
/// `View.glassCard()` modifier olarak kullanılır.
public struct GlassCardModifier: ViewModifier {
    public var cornerRadius: CGFloat = Spacing.radiusMedium
    public var elevated: Bool = false

    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(elevated ? BrandColor.surfaceElevated.opacity(0.6) : BrandColor.surface.opacity(0.6))
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
            }
    }
}

public extension View {
    func glassCard(cornerRadius: CGFloat = Spacing.radiusMedium, elevated: Bool = false) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, elevated: elevated))
    }
}
