package com.budgetella.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import androidx.core.content.getSystemService
import com.budgetella.app.core.locale.LocaleHelper
import com.budgetella.app.data.seed.DataInitializer
import com.google.firebase.FirebaseApp
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject

/**
 * App entry point — Firebase init, default-locale override, FCM channel setup.
 * Mirrors the iOS BudgetellaApp.init() flow:
 *   1. First-launch language default → English (regardless of system locale).
 *   2. Firebase configure (reads google-services.json — drop yours into app/).
 *   3. Notification channel registration so push payloads have somewhere to land.
 */
@HiltAndroidApp
class BudgetellaApplication : Application() {

    @Inject lateinit var dataInitializer: DataInitializer

    override fun onCreate() {
        super.onCreate()

        // 1. First-launch English default — matches the iOS `defaultLanguageApplied`
        //    flag so the app boots in English everywhere on day one.
        LocaleHelper.applyDefaultLanguageIfFirstLaunch(this)
        // 1b. Re-apply the saved locale on every cold start so it survives
        //     even when the OS forgot it (older Android, missing locales_config,
        //     aggressive OEM background killers wiping per-app locale state).
        LocaleHelper.applySavedLanguage(this)

        // 2. Firebase configure. Until google-services.json is added (per the
        //    README), the Firebase plugin will fail to apply, so this call is
        //    wrapped to keep IDE preview / unit tests usable.
        runCatching { FirebaseApp.initializeApp(this) }

        // 3. Default notification channel for FCM. iOS uses UNNotificationCategory
        //    for the equivalent; here it's a single low-importance channel that
        //    push payloads can opt into via android:default_notification_channel_id.
        registerDefaultNotificationChannel()

        // 4. Seed default categories + AppSettings row for the local-only user.
        //    Mirrors iOS BudgetellaApp.seedCategoriesIfNeeded / seedSettingsIfNeeded.
        //    Runs again with the real Firebase UID after sign-in (M2).
        dataInitializer.seedFor(DataInitializer.LOCAL_USER_ID)
    }

    private fun registerDefaultNotificationChannel() {
        val manager = getSystemService<NotificationManager>() ?: return
        val channel = NotificationChannel(
            DEFAULT_CHANNEL_ID,
            getString(R.string.notif_channel_default_name),
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = getString(R.string.notif_channel_default_description)
            enableVibration(true)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val DEFAULT_CHANNEL_ID: String = "budgetella_default"
    }
}
