//
//  NotificationService.swift
//  Budgetella
//
//  FCM + UNUserNotificationCenter entegrasyonu.
//
//  Sorumluluklar:
//  1. UNUserNotificationCenterDelegate — foreground banner gösterimi + tap yanıtı
//  2. MessagingDelegate — FCM token yönetimi
//  3. FCM token → Firestore users/{uid}/fcmToken
//  4. Gelen push payload → .appPushReceived Notification ile ContentView'a ilet
//  5. Deep link URL → .appDeepLinkReceived Notification ile MainTabView'a ilet
//
//  Swift 6 notu: nonisolated delegate metotlarında actor boundary'yi geçmeden önce
//  tüm değerler Sendable String'e dönüştürülür; [AnyHashable: Any] Task'a taşınmaz.
//

import Foundation
import UserNotifications
@preconcurrency import FirebaseMessaging
@preconcurrency import FirebaseFirestore

// MARK: - Notification names

extension Notification.Name {
    /// Payload: userInfo["url"] = URL  — deep link navigate için
    static let appDeepLinkReceived = Notification.Name("appDeepLinkReceived")

    /// Payload: userInfo["title"], ["body"], ["kind"], ["deepLink"]
    /// ContentView dinleyerek NotificationRecord ekler.
    static let appPushReceived = Notification.Name("appPushReceived")

    /// Bildirim kutusu aç — DashboardView dinler, showNotifications = true yapar.
    static let appShowNotifications = Notification.Name("appShowNotifications")
}

// MARK: - NotificationService

@MainActor
final class NotificationService: NSObject {

    static let shared = NotificationService()

    /// Stores the deep-link URL from a push-notification tap so that
    /// `MainTabView` can handle it on cold launch, before any views are mounted.
    /// Cleared immediately once consumed.
    var pendingDeepLinkURL: URL?

    /// Fallback deep-link when a push notification carries no `deepLink` key.
    static let notificationsInboxURL = URL(string: "budgetella://notifications")!

    private override init() { super.init() }

    // MARK: - Setup

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        // Her app açılışında APNs kaydını yenile — izin varsa APNs token gelir →
        // Messaging.apnsToken set edilir → MessagingDelegate FCM token üretir.
        // İzin yoksa iOS bunu sessizce ignore eder.
        Task {
            let status = await UNUserNotificationCenter.current().notificationSettings()
            guard status.authorizationStatus == .authorized else { return }
            await UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Permission + APNs registration

    func requestPermissionAndRegister() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        guard granted else { return }
        await UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - FCM token → Firestore

    func syncToken(_ token: String, userId: String) {
        guard !userId.isEmpty else { return }
        print("[FCM] Writing token to Firestore for uid: \(userId)")
        Firestore.firestore()
            .collection("users").document(userId)
            .setData(["fcmToken": token,
                      "fcmTokenUpdatedAt": FieldValue.serverTimestamp()],
                     merge: true) { error in
            if let error {
                print("[FCM] Firestore write FAILED: \(error.localizedDescription)")
            } else {
                print("[FCM] Firestore write SUCCESS ✓")
            }
        }
    }

    /// Login sonrası çağır — token login'den önce geldiyse Firestore'a yazar.
    /// APNs token henüz gelmemişse 5'e kadar exponential backoff ile retry eder.
    func syncPendingTokenIfNeeded(userId: String, attempt: Int = 1) {
        guard !userId.isEmpty else { return }

        // 1. Önce UserDefaults cache'e bak — MessagingDelegate daha önce attıysa vardır
        if let cached = UserDefaults.standard.string(forKey: "pendingFCMToken"), !cached.isEmpty {
            print("[FCM] Using cached token (attempt \(attempt)): \(cached.prefix(20))...")
            syncToken(cached, userId: userId)
            return
        }

        // 2. Firebase'den al (APNs token hazırsa anında döner)
        Messaging.messaging().token { [weak self] token, error in
            if let token, error == nil {
                print("[FCM] Got fresh token: \(token.prefix(20))...")
                UserDefaults.standard.set(token, forKey: "pendingFCMToken")
                Task { @MainActor in
                    self?.syncToken(token, userId: userId)
                }
            } else if attempt <= 6 {
                // APNs henüz hazır değil — artan beklemeyle retry (3, 6, 9, 12, 15, 18 sn)
                let delay = Double(attempt) * 3.0
                print("[FCM] APNs not ready, retry \(attempt)/6 in \(Int(delay))s...")
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    self?.syncPendingTokenIfNeeded(userId: userId, attempt: attempt + 1)
                }
            } else {
                print("[FCM] All retries exhausted. MessagingDelegate will sync when token arrives.")
            }
        }
    }

    func removeToken(userId: String) {
        guard !userId.isEmpty else { return }
        Firestore.firestore()
            .collection("users").document(userId)
            .updateData(["fcmToken": FieldValue.delete()])
    }

    // MARK: - Internal dispatch

    private func dispatchPushReceived(title: String, body: String,
                                      kind: String, deepLink: String?) {
        var payload: [String: Any] = ["title": title, "body": body, "kind": kind]
        if let dl = deepLink { payload["deepLink"] = dl }
        NotificationCenter.default.post(name: .appPushReceived, object: nil, userInfo: payload)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {

    /// Uygulama ön plandayken gelen bildirimleri banner olarak göster.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handler([.banner, .badge, .sound])

        // Extract Sendable Strings before crossing actor boundary
        let title    = notification.request.content.title
        let body     = notification.request.content.body
        let kind     = notification.request.content.userInfo["kind"]     as? String
                       ?? NotificationKind.systemMessage.rawValue
        let deepLink = notification.request.content.userInfo["deepLink"] as? String

        Task { @MainActor in
            self.dispatchPushReceived(title: title, body: body, kind: kind, deepLink: deepLink)
        }
    }

    /// Kullanıcı bildirime tıkladı → deep link varsa navigate et.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler handler: @escaping () -> Void
    ) {
        // Extract Sendable Strings before crossing actor boundary
        let title    = response.notification.request.content.title
        let body     = response.notification.request.content.body
        let kind     = response.notification.request.content.userInfo["kind"]     as? String
                       ?? NotificationKind.systemMessage.rawValue
        let deepLink = response.notification.request.content.userInfo["deepLink"] as? String

        // handler() MUST be called synchronously, before the Task runs.
        // Moving it inside the Task would violate Apple's delegate contract and
        // prevent the system from cleaning up the notification. This is intentional.
        handler()

        Task { @MainActor in
            // Deep link varsa oraya git; yoksa bildirim kutusunu aç
            let destination: URL = {
                if let dl = deepLink, let url = URL(string: dl) { return url }
                return NotificationService.notificationsInboxURL
            }()
            // Store for cold-launch: if MainTabView isn't mounted yet the
            // NotificationCenter post below fires into the void. The .task
            // modifier in MainTabView consumes pendingDeepLinkURL on first appear.
            self.pendingDeepLinkURL = destination
            NotificationCenter.default.post(
                name: .appDeepLinkReceived,
                object: nil,
                userInfo: ["url": destination]
            )
            self.dispatchPushReceived(title: title, body: body, kind: kind, deepLink: deepLink)
        }
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {

    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("[FCM] Token: \(token)")
        // Her zaman cache'le — login'den önce gelirse syncPendingTokenIfNeeded alır
        UserDefaults.standard.set(token, forKey: "pendingFCMToken")
        Task { @MainActor in
            let uid = UserDefaults.standard.string(forKey: "currentUserId") ?? ""
            self.syncToken(token, userId: uid)   // uid boşsa guard içinde kesilir
        }
    }
}

// MARK: - Local notifications

extension NotificationService {

    /// Bildirim toggle açılınca anında test bildirimi — 2 saniye sonra gelir.
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = LocaleHelper.string("Bildirimler Aktif ✓")
        content.body  = LocaleHelper.string("Budgetella bildirimleri başarıyla etkinleştirildi.")
        content.sound = .default
        content.userInfo = ["kind": NotificationKind.systemMessage.rawValue]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let req = UNNotificationRequest(
            identifier: "notif-test-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(req)
    }

    /// Achievement unlock — anında göster.
    func scheduleAchievementNotification(title: String, body: String) {
        guard UserDefaults.standard.bool(forKey: "notifAllEnabled") else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        content.userInfo = ["kind": NotificationKind.achievement.rawValue]

        let req = UNNotificationRequest(
            identifier: "achievement-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req)
    }

    /// Haftalık özet — her Pazartesi 09:00, tekrar eden.
    func scheduleWeeklyDigest() {
        let center = UNUserNotificationCenter.current()
        guard UserDefaults.standard.bool(forKey: "notifAllEnabled"),
              UserDefaults.standard.bool(forKey: "notifWeeklyDigest") else {
            center.removePendingNotificationRequests(withIdentifiers: ["weekly-digest"])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = LocaleHelper.string("Haftalık Özet 📊")
        content.body  = LocaleHelper.string("Bu haftanın harcama özetin hazır. Bir bak!")
        content.sound = .default
        content.userInfo = [
            "kind":     NotificationKind.weeklyDigest.rawValue,
            "deepLink": "budgetella://stats"
        ]

        var comps = DateComponents()
        comps.weekday = 2  // Pazartesi
        comps.hour    = 9
        comps.minute  = 0

        let req = UNNotificationRequest(
            identifier: "weekly-digest",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        )
        center.add(req)
    }

    /// Anomali uyarısı — büyük/alışılmadık harcama tespit edilince.
    func scheduleAnomalyAlert(transactionNote: String, amount: String) {
        guard UserDefaults.standard.bool(forKey: "notifAllEnabled"),
              UserDefaults.standard.bool(forKey: "notifAnomalyAlerts") else { return }

        let content = UNMutableNotificationContent()
        content.title = LocaleHelper.string("Alışılmadık Harcama ⚠️")
        content.body  = "\(transactionNote) — \(amount)"
        content.sound = .default
        content.userInfo = [
            "kind":     NotificationKind.anomaly.rawValue,
            "deepLink": "budgetella://transactions"
        ]

        let req = UNNotificationRequest(
            identifier: "anomaly-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req)
    }
}
