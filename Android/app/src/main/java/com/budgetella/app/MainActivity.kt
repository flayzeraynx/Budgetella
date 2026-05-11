package com.budgetella.app

import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.fragment.app.FragmentActivity
import com.budgetella.app.core.design.BudgetellaTheme
import com.budgetella.app.ui.AppRoot
import dagger.hilt.android.AndroidEntryPoint

/**
 * Single-activity host. The Compose tree under [AppRoot] handles every screen
 * — the activity exists only to install the splash screen, draw edge-to-edge,
 * and mount Hilt's entry point.
 *
 * Extends [FragmentActivity] (not the leaner ComponentActivity) because
 * androidx.biometric.BiometricPrompt's constructor requires a FragmentActivity
 * host. FragmentActivity extends ComponentActivity so nothing downstream
 * regresses — every ComposeView, Hilt entry-point and ActivityResult contract
 * still works unchanged.
 */
@AndroidEntryPoint
class MainActivity : FragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Splash screen API — keeps the launcher icon visible across the cold
        // start gap, then crossfades into the Compose tree. Mirrors the iOS
        // SplashView delay-into-AppState routing.
        installSplashScreen()
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)

        setContent {
            BudgetellaTheme {
                AppRoot()
            }
        }
    }
}
