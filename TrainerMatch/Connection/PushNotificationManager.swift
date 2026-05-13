//
//  PushNotificationManager.swift
//  TrainerMatch
//
//  Cross-device push notifications via OneSignal.
//  SDK is now installed — all lines active.
//

import SwiftUI
import UserNotifications
import OneSignalFramework

// MARK: - Push Notification Manager

class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()

    // Paste your App ID from onesignal.com → Settings → Keys & IDs
    private let oneSignalAppId = "0aedf585-a2ab-468a-89bf-115ba2f5eec6"
    private override init() { super.init() }

    // MARK: - Initialize on app launch

    func initialize() {
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        OneSignal.initialize(oneSignalAppId, withLaunchOptions: nil)
        OneSignal.Notifications.requestPermission({ accepted in
            print("OneSignal permission: \(accepted)")
        }, fallbackToSettings: false)

        // Register click listener
        OneSignal.Notifications.addClickListener(self)
    }

    // MARK: - Login after Supabase auth

    func loginUser(userId: String) {
        OneSignal.login(userId)
        print("✅ OneSignal: logged in \(userId)")
    }

    // MARK: - Logout on sign out

    func logoutUser() {
        OneSignal.logout()
        print("OneSignal: logged out")
    }

    // MARK: - Request permission

    func requestPermission() {
        OneSignal.Notifications.requestPermission({ accepted in
            print("Push permission: \(accepted)")
        }, fallbackToSettings: true)
    }
}

// MARK: - Notification click handler

extension PushNotificationManager: OSNotificationClickListener {
    func onClick(event: OSNotificationClickEvent) {
        guard let data = event.notification.additionalData else { return }
        let table    = data["table"]     as? String ?? ""
        let senderId = data["sender_id"] as? String ?? ""
        NotificationCenter.default.post(
            name: .tmPushNotificationTapped,
            object: nil,
            userInfo: ["table": table, "sender_id": senderId]
        )
    }
}

extension Notification.Name {
    static let tmPushNotificationTapped = Notification.Name("tmPushNotificationTapped")
}
