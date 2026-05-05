//
//  AppDelegate.swift
//  Budgetella
//
//  UIApplicationDelegate — APNs device token Firebase'e iletilir.
//  SwiftUI @main app'lerde UIApplicationDelegateAdaptor ile mount edilir.
//

import UIKit
@preconcurrency import FirebaseMessaging

final class AppDelegate: NSObject, UIApplicationDelegate {

    /// APNs'ten gelen raw device token'ı Firebase SDK'ya ilet.
    /// Firebase bunu kendi FCM token'ına dönüştürür.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[APNs] Registration failed: \(error.localizedDescription)")
    }
}
