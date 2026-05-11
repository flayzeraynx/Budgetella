package com.budgetella.app

import android.os.Bundle
import android.util.Log
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.budgetella.app.core.design.BudgetellaTheme
import com.budgetella.app.ui.AppRoot
import dagger.hilt.android.AndroidEntryPoint

/**
 * Single-activity host. The Compose tree under [AppRoot] handles every screen
 * — the activity exists only to install the splash screen, draw edge-to-edge,
 * and mount Hilt's entry point.
 *
 * Extends [AppCompatActivity] (which extends FragmentActivity, so BiometricPrompt
 * still works). The AppCompat dependency is load-bearing: AppCompatDelegate's
 * per-app locale support (`setApplicationLocales`) only takes effect when at
 * least one AppCompatDelegate is registered with the framework — switching
 * from a plain FragmentActivity to AppCompatActivity is what registers it
 * and makes Settings → Language actually persist across launches.
 */
@AndroidEntryPoint
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Splash screen API — keeps the launcher icon visible across the cold
        // start gap, then crossfades into the Compose tree. Mirrors the iOS
        // SplashView delay-into-AppState routing.
        installSplashScreen()
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)

        // Locale diagnostics — visible via `adb logcat -s BUDGETELLA_LOCALE` so
        // we can confirm which language the Activity actually came up with.
        val appLocales = AppCompatDelegate.getApplicationLocales().toLanguageTags()
        val cfgLocales = resources.configuration.locales.toLanguageTags()
        Log.d(
            "BUDGETELLA_LOCALE",
            "MainActivity.onCreate — appLocales='$appLocales' cfgLocales='$cfgLocales'"
        )

        setContent {
            BudgetellaTheme {
                AppRoot()
            }
        }
    }
}
