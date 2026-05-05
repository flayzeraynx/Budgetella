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
}

// MARK: - NotificationService

@MainActor
final class NotificationService: NSObject {

    static let shared = NotificationService()

    private override init() { super.init() }

    // MARK: - Setup

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
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
        Firestore.firestore()
            .collection("users").document(userId)
            .setData(["fcmToken": token,
                      "fcmTokenUpdatedAt": FieldValue.serverTimestamp()],
                     merge: true)
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

        Task { @MainActor in
            if let dl = deepLink, let url = URL(string: dl) {
                NotificationCenter.default.post(
                    name: .appDeepLinkReceived,
                    object: nil,
                    userInfo: ["url": url]
                )
            }
            self.dispatchPushReceived(title: title, body: body, kind: kind, deepLink: deepLink)
        }
        handler()
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {

    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("[FCM] Token: \(token)")
        Task { @MainActor in
            let uid = UserDefaults.standard.string(forKey: "currentUserId") ?? ""
            self.syncToken(token, userId: uid)
        }
    }
}

// MARK: - Local notifications

extension NotificationService {

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
