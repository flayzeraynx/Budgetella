//
//  Typography.swift
//  Budgetella
//
//  Tasarımda Inter font ailesi kullanılıyor; sistem fallback olarak SF Pro.
//  Inter font'u Resources'a `Inter-*.ttf` olarak eklenip Info.plist
//  `UIAppFonts` array'inde register edilmeli.
//
//  Şimdilik (font asset eklenene kadar) sistem font scale'i kullanıyoruz —
//  Inter geldiğinde `baseFont(_:weight:)` içeriğini değiştirmek yeterli.
//
//  Kullanım:
//    Text("Para, nihayet net.").font(.brand(.display))
//    Text("İşlemler").font(.brand(.title))
//

import SwiftUI

/// Brand typography ölçek — tasarımdaki hiyerarşiye birebir.
public enum BrandFont {

    case display       // 56 / bold / -1.5 tracking — onboarding hero
    case displayHero   // 38 / bold / tabular-nums — transaction tutar hero'su
    case largeTitle    // 36 / bold — ekran başlığı
    case title         // 28 / semibold — kart başlığı
    case headline      // 20 / semibold — list group header
    case subheadline   // 17 / semibold — strong body
    case body          // 16 / regular — varsayılan paragraf
    case callout       // 15 / regular
    case footnote      // 13 / regular — yardımcı metin
    case caption       // 12 / medium — etiket / chip
    case caption2      // 11 / semibold / +0.5 tracking — uppercase eyebrow

    public var size: CGFloat {
        switch self {
        case .display:      return 56
        case .displayHero:  return 38
        case .largeTitle:   return 36
        case .title:        return 28
        case .headline:     return 20
        case .subheadline:  return 17
        case .body:         return 16
        case .callout:      return 15
        case .footnote:     return 13
        case .caption:      return 12
        case .caption2:     return 11
        }
    }

    public var weight: Font.Weight {
        switch self {
        case .display, .displayHero, .largeTitle: return .bold
        case .title, .headline, .subheadline: return .semibold
        case .body, .callout, .footnote:   return .regular
        case .caption:                     return .medium
        case .caption2:                    return .semibold
        }
    }

    public var tracking: CGFloat {
        switch self {
        case .display:      return -1.5
        case .displayHero:  return -0.8
        case .largeTitle:   return -0.8
        case .title:        return -0.4
        case .caption2:     return 0.5
        default:            return 0
        }
    }

    public var isMonospaced: Bool {
        self == .displayHero
    }

    public var lineSpacing: CGFloat {
        switch self {
        case .display:     return 6
        case .displayHero: return 0
        case .largeTitle:  return 4
        case .title:       return 2
        case .body, .callout, .subheadline: return 2
        default:           return 0
        }
    }
}

public extension Font {
    /// Brand font helper: `Font.brand(.display)`.
    /// Şu an system font kullanır; Inter Resources'a eklendiğinde burayı
    /// `.custom("Inter-\(weightName)", size:)` olarak değiştir.
    static func brand(_ token: BrandFont) -> Font {
        let base = Font.system(size: token.size, weight: token.weight, design: .default)
        return token.isMonospaced ? base.monospacedDigit() : base
    }
}

public extension View {
    /// `.brandFont(.display)` — font + tracking + lineSpacing'i tek seferde uygular.
    func brandFont(_ token: BrandFont) -> some View {
        self
            .font(.brand(token))
            .tracking(token.tracking)
            .lineSpacing(token.lineSpacing)
    }
}
