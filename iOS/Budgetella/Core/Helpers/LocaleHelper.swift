//
//  LocaleHelper.swift
//  Budgetella
//
//  Runtime locale helper — reads AppleLanguages override instead of
//  Bundle.main's cached-at-launch language. Used in ViewModels and
//  Foundation code where String(localized:) doesn't respect the SwiftUI
//  .environment(\.locale, …) injection.
//

import Foundation

enum LocaleHelper {

    /// The active language code set by the user (e.g. "en", "tr").
    static var currentLanguageCode: String {
        UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first ?? "tr"
    }

    /// Locale built from the user-selected language code.
    static var currentLocale: Locale {
        Locale(identifier: currentLanguageCode)
    }

    /// Look up a localized string from the correct .lproj bundle at runtime,
    /// bypassing Bundle.main's startup-cached language selection.
    static func string(_ key: String, value fallback: String? = nil) -> String {
        let langCode = currentLanguageCode
        if let path = Bundle.main.path(forResource: langCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: fallback ?? key, table: nil)
        }
        return NSLocalizedString(key, value: fallback ?? key, comment: "")
    }

    /// True when the user has selected English.
    static var isEnglish: Bool { currentLanguageCode.hasPrefix("en") }
}
