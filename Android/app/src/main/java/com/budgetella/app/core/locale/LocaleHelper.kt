package com.budgetella.app.core.locale

import android.app.LocaleManager
import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.os.LocaleList
import android.util.Log
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.content.edit
import androidx.core.os.LocaleListCompat
import java.util.Locale

/**
 * Set the per-app locale through the most direct API available. On Android
 * 13+ we go straight to the platform [LocaleManager]; pre-13 we fall through
 * to AppCompatDelegate. Going through AppCompatDelegate alone was the bug
 * that left `appLocales=''` in the diagnostics output — AppCompatDelegate
 * iterates `sActivityDelegates` to find the LocaleManager, and that list is
 * empty if no AppCompatActivity has registered yet.
 */
private fun forceApplicationLocale(context: Context, tag: String) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        val lm = context.getSystemService(LocaleManager::class.java)
        lm?.applicationLocales = LocaleList.forLanguageTags(tag)
    }
    // Always call AppCompatDelegate too so the pre-T fallback path runs on
    // older devices and the in-process AppCompat machinery (cached locales
    // for the activity stack, recreate hooks) stays in sync.
    AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(tag))
}

/** Filter Android Studio's logcat with this to follow language-switch flow. */
private const val LOG_TAG = "BUDGETELLA_LOCALE"

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
        if (prefs.getBoolean(KEY_DEFAULT_APPLIED, false)) {
            Log.d(LOG_TAG, "applyDefaultLanguageIfFirstLaunch: already applied, skip")
            return
        }
        Log.d(LOG_TAG, "applyDefaultLanguageIfFirstLaunch: forcing English on first launch")
        forceApplicationLocale(context, "en")
        prefs.edit {
            putBoolean(KEY_DEFAULT_APPLIED, true)
            putString(KEY_USER_LANGUAGE, Language.English.tag)
        }
    }

    /**
     * Re-apply whatever language we have in SharedPrefs on top of the OS's
     * per-app locale state. Safety net for when the platform forgot the
     * choice (older OS versions, missing localeConfig in early builds, etc.).
     * Cheap and idempotent — call it from Application.onCreate so every cold
     * launch lands in the user's chosen language, not the device default.
     */
    fun applySavedLanguage(context: Context) {
        val saved = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_USER_LANGUAGE, null)
        val current = AppCompatDelegate.getApplicationLocales().toLanguageTags()
        val cfg = describeConfigLocale(context)
        Log.d(LOG_TAG, "applySavedLanguage: pref='$saved' appLocales='$current' cfg='$cfg'")
        if (saved == null) return
        val currentTag = current.substringBefore(',').ifBlank { null }
        if (currentTag != null && currentTag.startsWith(saved, ignoreCase = true)) {
            Log.d(LOG_TAG, "applySavedLanguage: already in '$saved', no-op")
            return
        }
        Log.d(LOG_TAG, "applySavedLanguage: forcing '$saved' (was '$current')")
        forceApplicationLocale(context, saved)
    }

    /** Snapshot of the Activity's current Configuration locale for diagnostics. */
    private fun describeConfigLocale(context: Context): String {
        val cfg: Configuration = context.resources.configuration
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            cfg.locales.toLanguageTags()
        } else {
            @Suppress("DEPRECATION")
            cfg.locale.toLanguageTag()
        }
    }

    /** Persist + apply a language change. Triggers an activity recreate. */
    fun setLanguage(context: Context, language: Language) {
        val before = AppCompatDelegate.getApplicationLocales().toLanguageTags()
        val cfgBefore = describeConfigLocale(context)
        Log.d(LOG_TAG, "setLanguage($language) — before: appLocales='$before' cfg='$cfgBefore'")

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit { putString(KEY_USER_LANGUAGE, language.tag) }
        forceApplicationLocale(context, language.tag)

        val after = AppCompatDelegate.getApplicationLocales().toLanguageTags()
        val cfgAfter = describeConfigLocale(context)
        Log.d(LOG_TAG, "setLanguage($language) — after:  appLocales='$after' cfg='$cfgAfter' (pref='${language.tag}')")
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
