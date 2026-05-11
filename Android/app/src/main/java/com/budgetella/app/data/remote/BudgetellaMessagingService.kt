package com.budgetella.app.data.remote

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.content.getSystemService
import com.budgetella.app.BudgetellaApplication
import com.budgetella.app.MainActivity
import com.budgetella.app.R
import com.budgetella.app.data.local.entity.NotificationKind
import com.budgetella.app.data.local.entity.NotificationRecordEntity
import com.budgetella.app.data.prefs.UserPrefs
import com.budgetella.app.data.repository.NotificationRepository
import com.budgetella.app.data.seed.DataInitializer
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import java.util.UUID
import javax.inject.Inject

/**
 * FCM entry point — same payload shape as the iOS NotificationService.
 *
 * Payload contract (from the cloud function that fans out pushes):
 *   data: {
 *     title:    "…",
 *     body:     "…",
 *     kind:     "weekly_digest" | "budget_alert" | ...,
 *     deepLink: "budgetella://…"   (optional)
 *   }
 *
 * Per-message we persist a NotificationRecord (so the inbox stays in sync
 * with the system tray) and post a standard system notification that opens
 * MainActivity on tap.
 */
@AndroidEntryPoint
class BudgetellaMessagingService : FirebaseMessagingService() {

    @Inject lateinit var notificationRepository: NotificationRepository
    @Inject lateinit var userPrefs: UserPrefs
    @Inject lateinit var firestore: FirebaseFirestore

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onDestroy() {
        // Cancel in-flight upserts/awaits so they don't outlive the service.
        scope.cancel()
        super.onDestroy()
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val data = message.data
        val title = data["title"] ?: message.notification?.title ?: getString(R.string.app_name)
        val body = data["body"] ?: message.notification?.body ?: ""
        val kindRaw = data["kind"] ?: NotificationKind.SystemMessage.raw
        val deepLink = data["deepLink"]

        scope.launch {
            val uid = userPrefs.currentUserId.first()
                .ifBlank { DataInitializer.LOCAL_USER_ID }
            notificationRepository.record(
                NotificationRecordEntity(
                    id = UUID.randomUUID().toString(),
                    userId = uid,
                    kindRaw = kindRaw,
                    title = title,
                    body = body,
                    deepLink = deepLink,
                    isRead = false,
                    createdAt = System.currentTimeMillis(),
                )
            )
        }

        postTrayNotification(title, body, deepLink)
    }

    override fun onNewToken(token: String) {
        // Mirror to Firestore so the cloud-function fan-out can target this
        // device. iOS uses the same shape under `users/{uid}/devices/{token}`.
        scope.launch {
            val uid = userPrefs.currentUserId.first()
            if (uid.isBlank() || uid == DataInitializer.LOCAL_USER_ID) return@launch
            runCatching {
                firestore.collection("users").document(uid)
                    .collection("devices").document(token)
                    .set(mapOf("platform" to "android", "createdAt" to System.currentTimeMillis()))
                    .await()
            }
        }
    }

    private fun postTrayNotification(title: String, body: String, deepLink: String?) {
        val manager = getSystemService<NotificationManager>() ?: return
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            deepLink?.let { putExtra("deepLink", it) }
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, BudgetellaApplication.DEFAULT_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(getColor(R.color.brand_primary))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .build()

        manager.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), notification)
    }
}
