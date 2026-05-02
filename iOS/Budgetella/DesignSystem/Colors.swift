//
//  Colors.swift
//  Budgetella
//
//  Tasarım dili: "koyu glass premium". Aksent #6E5BFF.
//  V1'de hem dark hem light theme destekleniyor (system follow default);
//  UIColor dynamic provider ile dark/light otomatik resolve.
//
//  Kullanım:
//    BrandColor.primary          → #6E5BFF (theme-aware)
//    BrandColor.surface          → glass card background (adaptive)
//    BrandColor.income           → semantic gelir
//    BrandColor.expense          → semantic gider
//

import SwiftUI
import UIKit

// MARK: - UIColor hex initializer

extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else {
            self.init(white: 0.5, alpha: 1); return
        }
        let r = CGFloat((value & 0xFF0000) >> 16) / 255
        let g = CGFloat((value & 0x00FF00) >> 8)  / 255
        let b = CGFloat( value & 0x0000FF)         / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - BrandColor

public enum BrandColor {

    // ── Aksent (mode-independent)
    public static let primary      = Color(hex: "#6E5BFF")
    public static let primaryLight = Color(hex: "#8B6FFF")

    // ── Backgrounds (dark → deep navy; light → soft lavender-white)
    public static var background: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: "#0A0B14") : UIColor(hex: "#F5F6FE")
        })
    }
    public static var background2: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: "#14152A") : UIColor(hex: "#ECEEF9")
        })
    }
    public static var background3: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: "#1A1740") : UIColor(hex: "#E4E5F4")
        })
    }

    // ── Surfaces
    public static var surface: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: "#11141C") : UIColor(hex: "#FFFFFF")
        })
    }
    public static var surfaceElevated: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: "#1A1F2E") : UIColor(hex: "#F0F1FA")
        })
    }

    // ── Text
    public static var textPrimary: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: "#FFFFFF") : UIColor(hex: "#1A1B2E")
        })
    }
    public static var textSecondary: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.72)
                : UIColor(hex: "#1A1B2E").withAlphaComponent(0.72)
        })
    }
    public static var textTertiary: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.50)
                : UIColor(hex: "#1A1B2E").withAlphaComponent(0.50)
        })
    }

    // ── Borders
    public static var borderSubtle: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.08)
        })
    }
    public static var borderMedium: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.16)
                : UIColor.black.withAlphaComponent(0.16)
        })
    }

    // ── Semantic financial (same in both modes)
    public static let income  = Color(hex: "#10F2A5")
    public static let expense = Color(hex: "#FB7185")
    public static let warning = Color(hex: "#F59E0B")
    public static let info    = Color(hex: "#06B6D4")
}

public extension Color {
    static let brand = BrandColor.self
}

// MARK: - Hex initializer (Color)

public extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else {
            self = .gray; return
        }
        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8)  / 255.0
        let b = Double( value & 0x0000FF)         / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - GlassCard modifier

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
