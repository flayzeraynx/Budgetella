package com.budgetella.app.core.locale

import android.content.Context
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.content.edit
import androidx.core.os.LocaleListCompat
import java.util.Locale

/**
 * Runtime locale helper — mirrors iOS LocaleHelper.swift.
 *
 * Behaviour parity with iOS:
 *  - First launch on any device → force English regardless of system locale.
 *    iOS does this by setting `AppleLanguages = ["en"]` in the App.init()
 *    before Bundle.main caches. Here we use AppCompatDelegate's per-app
 *    locale (Android 13+) plus a SharedPrefs flag so subsequent launches
 *    honour whatever the user picked in Settings.
 *  - Setting the language at runtime triggers an activity recreate. The UI
 *    layer shows a brief shimmer overlay during the transition, same as iOS.
 *
 * Supported languages in v1: English, Turkish. German is reserved for v2.
 */
object LocaleHelper {

    private const val PREFS_NAME = "budgetella.locale"
    private const val KEY_DEFAULT_APPLIED = "defaultLanguageApplied"
    private const val KEY_USER_LANGUAGE = "userLanguage"

    enum class Language(val tag: String, val displayName: String) {
        English("en", "English"),
        Turkish("tr", "Türkçe"),
        // German is shipped in v2 — keep the enum stable so persisted
        // userLanguage strings still parse round-trip.
        German("de", "Deutsch"),
    }

    /** Apply English-as-default on the very first launch. No-op afterwards. */
    fun applyDefaultLanguageIfFirstLaunch(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (prefs.getBoolean(KEY_DEFAULT_APPLIED, false)) return

        AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags("en"))
        prefs.edit {
            putBoolean(KEY_DEFAULT_APPLIED, true)
            putString(KEY_USER_LANGUAGE, Language.English.tag)
        }
    }

    /** Persist + apply a language change. Triggers an activity recreate. */
    fun setLanguage(context: Context, language: Language) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit { putString(KEY_USER_LANGUAGE, language.tag) }
        AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(language.tag))
    }

    /** Currently active language; falls back to English. */
    fun currentLanguage(context: Context): Language {
        val tag = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_USER_LANGUAGE, Language.English.tag)
            ?: Language.English.tag
        return Language.entries.firstOrNull { it.tag.equals(tag, ignoreCase = true) }
            ?: Language.English
    }

    /** Convenience: Locale for date/number formatters. */
    fun currentLocale(context: Context): Locale = Locale.forLanguageTag(currentLanguage(context).tag)
}
