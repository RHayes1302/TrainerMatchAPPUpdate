//
//  PushNotificationManager.swift
//  TrainerMatch
//

import SwiftUI
import UserNotifications
import OneSignalFramework

class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()
    private let oneSignalAppId = "0aedf585-a2ab-468a-89bf-115ba2f5eec6"
    private let restApiKey = "Key os_v2_app_blw7lbncvndivcn7cfn2f5poy2xi3nlgatcus5f6nrel2ewjlbmm4rtuvfq3wvrvp2sh2d55gvhbv4gicphau44qy4oaaw5zjwqy6sq"

    private override init() { super.init() }

    // MARK: - Initialize SDK

    func initialize() {
        // Set this app as the UNUserNotificationCenter delegate so iOS shows
        // banners even when the app is in the foreground.
        UNUserNotificationCenter.current().delegate = self

        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        OneSignal.initialize(oneSignalAppId, withLaunchOptions: nil)
        OneSignal.Notifications.requestPermission({ accepted in
            print("OneSignal permission: \(accepted)")
        }, fallbackToSettings: false)
        OneSignal.Notifications.addClickListener(self)
    }

    // MARK: - Login / Logout

    func loginUser(userId: String) {
        // Always uppercase to match iOS UUID format — ensures external_id
        // is consistent regardless of how the caller formats the UUID string.
        let normalizedId = userId.uppercased()
        OneSignal.login(normalizedId)
        print("✅ OneSignal: logged in as \(normalizedId)")
    }

    func logoutUser() {
        OneSignal.logout()
        print("OneSignal: logged out")
    }

    func requestPermission() {
        OneSignal.Notifications.requestPermission({ accepted in
            print("Push permission: \(accepted)")
        }, fallbackToSettings: true)
    }

    // MARK: - Notification helpers

    func sendNewClientNotification(toTrainerId: String, clientName: String) {
        print("🔔 Sending new client push to trainerId: \(toTrainerId)")
        sendPush(
            toExternalId: toTrainerId,
            heading:  "New Training Request! 💪",
            content:  "\(clientName) wants you as their trainer. Tap to review.",
            data:     ["action": "pending_requests", "trainer_id": toTrainerId]
        )
    }

    func sendTrainerAcceptedNotification(toClientId: String, trainerName: String) {
        print("🔔 Sending accepted push to clientId: \(toClientId)")
        sendPush(
            toExternalId: toClientId,
            heading:  "\(trainerName) accepted you! 🎉",
            content:  "You're now connected. Please complete your PAR-Q health form.",
            data:     ["action": "parq_prompt", "trainer_name": trainerName]
        )
    }

    func sendMessageNotification(toUserId: String, senderName: String, preview: String) {
        print("🔔 Sending message push to: \(toUserId)")
        sendPush(
            toExternalId: toUserId,
            heading:  "New message from \(senderName)",
            content:  preview.isEmpty ? "Sent you a message" : preview,
            data:     ["action": "open_chat", "sender_id": toUserId]
        )
    }

    func sendVideoCallNotification(toClientAuthId: String, trainerName: String, channel: String) {
        print("🔔 Sending video call push to: \(toClientAuthId)")
        sendPush(
            toExternalId: toClientAuthId,
            heading:  "\(trainerName) is calling... 📹",
            content:  "Tap to join the video call",
            data:     ["action": "video_call", "channel": channel, "trainer_name": trainerName]
        )
    }

    func sendVideoMessageNotification(toClientId: String, trainerName: String) {
        print("🔔 Sending video message push to clientId: \(toClientId)")
        sendPush(
            toExternalId: toClientId,
            heading:  "Your Trainer sent a video 🎥",
            content:  "Tap to view the video message from \(trainerName).",
            data:     ["action": "open_videos", "trainer_name": trainerName]
        )
    }

    // MARK: - Core send — targets by external_id (Supabase auth UUID)

    private func sendPush(
        toExternalId: String,
        heading:      String,
        content:      String,
        data:         [String: String]
    ) {
        guard let url = URL(string: "https://api.onesignal.com/notifications") else { return }

        // OneSignal stores external_id uppercase (iOS UUID format).
        // Supabase may return lowercase — uppercase to ensure case-sensitive match.
        let normalizedId = toExternalId.uppercased()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(restApiKey,         forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "app_id":          oneSignalAppId,
            "target_channel":  "push",
            "headings":        ["en": heading],
            "contents":        ["en": content],
            "data":            data,
            "include_aliases": ["external_id": [normalizedId]]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ OneSignal push failed: \(error.localizedDescription)")
                return
            }
            if let http = response as? HTTPURLResponse {
                print("OneSignal push status: \(http.statusCode)")
            }
            if let data = data, let str = String(data: data, encoding: .utf8) {
                print("OneSignal response: \(str)")
                if str.contains("invalid_aliases") {
                    print("⚠️ OneSignal: external_id '\(normalizedId)' not found — is the user logged in via OneSignal.login()?")
                }
            }
        }.resume()
    }
}

// MARK: - Foreground notification display
// Without this, iOS silently drops banners when the app is open.

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner, play sound, and update badge even when app is foregrounded
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

// MARK: - Notification click handler

extension PushNotificationManager: OSNotificationClickListener {
    func onClick(event: OSNotificationClickEvent) {
        let data        = event.notification.additionalData ?? [:]
        let action      = data["action"]       as? String ?? ""
        let trainerId   = data["trainer_id"]   as? String ?? ""
        let table       = data["table"]        as? String ?? ""
        let senderId    = data["sender_id"]    as? String ?? ""
        let channel     = data["channel"]      as? String ?? ""
        let trainerName = data["trainer_name"] as? String ?? ""

        NotificationCenter.default.post(
            name: .tmPushNotificationTapped,
            object: nil,
            userInfo: [
                "action":       action,
                "trainer_id":   trainerId,
                "table":        table,
                "sender_id":    senderId,
                "channel":      channel,
                "trainer_name": trainerName
            ]
        )
    }
}

extension Notification.Name {
    static let tmPushNotificationTapped = Notification.Name("tmPushNotificationTapped")
}
