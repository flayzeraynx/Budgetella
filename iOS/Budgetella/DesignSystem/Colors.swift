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

// MARK: - Press feedback
//
// Press highlights live in ButtonStyle.configuration.isPressed (not in a
// .simultaneousGesture(DragGesture) attached outside the Button). Why:
// SwiftUI's Button hands its touch tracking to the nearest UIScrollView's pan
// gesture, so when the user starts dragging on a row inside a List, the scroll
// view takes over and isPressed snaps back to false — matching the native iOS
// Settings behaviour the user expects. The prior modifier-with-DragGesture
// approach was capturing the touch and starving the List of vertical-pan
// events, breaking "drag from anywhere on the row to scroll".

/// List rows: brand-tinted highlight that fades on release or scroll cancellation.
public struct ListRowPressStyle: ButtonStyle {
    public var color: Color = BrandColor.primary.opacity(0.15)

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .background(configuration.isPressed ? color : Color.clear)
            // Instant ON, smooth OFF — matches the previous look-and-feel.
            .animation(configuration.isPressed ? .none : .easeOut(duration: 0.22),
                       value: configuration.isPressed)
    }
}

/// glassCard rows: subtle white wash + light spring scale, again driven by isPressed
/// so the parent scroll/page gesture can always preempt.
public struct CardPressStyle: ButtonStyle {
    public var cornerRadius: CGFloat = 14

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.14 : 0))
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(configuration.isPressed ? .none : .spring(response: 0.3, dampingFraction: 0.7),
                       value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == ListRowPressStyle {
    static var listRow: ListRowPressStyle { ListRowPressStyle() }
    static func listRow(color: Color) -> ListRowPressStyle { ListRowPressStyle(color: color) }
}
public extension ButtonStyle where Self == CardPressStyle {
    static func card(cornerRadius: CGFloat = 14) -> CardPressStyle { CardPressStyle(cornerRadius: cornerRadius) }
}

// MARK: - Back-compat shims
//
// Existing call sites compose `.buttonStyle(.plain).highlightOnPress(...)`. The
// modifiers below are now no-ops — call sites should migrate to
// `.buttonStyle(.listRow)` / `.buttonStyle(.card(cornerRadius:))` for the real
// press feedback. Kept as no-ops so nothing has to change in a single sweep.

public struct RowHighlightModifier: ViewModifier {
    var color: Color
    public func body(content: Content) -> some View { content }
}

public struct CardHighlightModifier: ViewModifier {
    var cornerRadius: CGFloat
    public func body(content: Content) -> some View { content }
}

public extension View {
    func highlightOnPress(color: Color = BrandColor.primary.opacity(0.15)) -> some View {
        modifier(RowHighlightModifier(color: color))
    }

    func cardHighlightOnPress(cornerRadius: CGFloat = 14) -> some View {
        modifier(CardHighlightModifier(cornerRadius: cornerRadius))
    }
}
