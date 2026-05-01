//
//  AppSettings.swift
//  Budgetella
//
//  SwiftData @Model — kullanıcı bazlı app tercihleri.
//  Hassas olmayan UI tercihleri (theme, dil, currency) burada;
//  auth token gibi hassas veriler Keychain'de.
//

import Foundation
import SwiftData

public enum AppTheme: String, Codable, CaseIterable, Sendable {
    case light
    case dark
    case system
}

public enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case turkish = "tr"
    case english = "en"
    case german = "de"

    public var displayName: String {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "English"
        case .german: return "Deutsch"
        }
    }

    public var flagEmoji: String {
        switch self {
        case .turkish: return "🇹🇷"
        case .english: return "🇺🇸"
        case .german: return "🇩🇪"
        }
    }
}

public enum AppCurrency: String, Codable, CaseIterable, Sendable {
    case tryLira = "TRY"
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"

    public var symbol: String {
        switch self {
        case .tryLira: return "₺"
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        }
    }
}

@Model
public final class AppSettings {

    @Attribute(.unique) public var userId: String

    public var currencyRaw: String  // AppCurrency.rawValue
    public var languageRaw: String  // AppLanguage.rawValue
    public var themeRaw: String     // AppTheme.rawValue

    public var hideAmounts: Bool
    public var biometricLockEnabled: Bool
    public var notificationsEnabled: Bool

    public var updatedAt: Date

    public init(
        userId: String,
        currency: AppCurrency = .tryLira,
        language: AppLanguage = .turkish,
        theme: AppTheme = .system,
        hideAmounts: Bool = false,
        biometricLockEnabled: Bool = false,
        notificationsEnabled: Bool = true
    ) {
        self.userId = userId
        self.currencyRaw = currency.rawValue
        self.languageRaw = language.rawValue
        self.themeRaw = theme.rawValue
        self.hideAmounts = hideAmounts
        self.biometricLockEnabled = biometricLockEnabled
        self.notificationsEnabled = notificationsEnabled
        self.updatedAt = .now
    }
}

public extension AppSettings {
    var currency: AppCurrency {
        get { AppCurrency(rawValue: currencyRaw) ?? .tryLira }
        set { currencyRaw = newValue.rawValue; updatedAt = .now }
    }

    var language: AppLanguage {
        get { AppLanguage(rawValue: languageRaw) ?? .turkish }
        set { languageRaw = newValue.rawValue; updatedAt = .now }
    }

    var theme: AppTheme {
        get { AppTheme(rawValue: themeRaw) ?? .system }
        set { themeRaw = newValue.rawValue; updatedAt = .now }
    }
}
