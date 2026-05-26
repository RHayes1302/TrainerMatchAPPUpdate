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
    private override init() { super.init() }

    func initialize() {
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        OneSignal.initialize(oneSignalAppId, withLaunchOptions: nil)
        OneSignal.Notifications.requestPermission({ accepted in
            print("OneSignal permission: \(accepted)")
        }, fallbackToSettings: false)
        OneSignal.Notifications.addClickListener(self)
    }

    func loginUser(userId: String) {
        OneSignal.login(userId)
        print("✅ OneSignal: logged in \(userId)")
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

    // MARK: - New client selected trainer — sends pending request notification

    func sendNewClientNotification(toTrainerId: String, clientName: String) {
        sendNotification(
            toUserId:  toTrainerId,
            heading:   "New Training Request! 💪",
            content:   "\(clientName) wants you as their trainer. Tap to review.",
            data:      ["action": "pending_requests", "trainer_id": toTrainerId]
        )
    }

    // MARK: - Trainer accepted client notification

    func sendTrainerAcceptedNotification(toClientId: String, trainerName: String) {
        sendNotification(
            toUserId:  toClientId,
            heading:   "\(trainerName) accepted you! 🎉",
            content:   "You're now connected. Please complete your PAR-Q health form.",
            data:      ["action": "parq_prompt", "trainer_name": trainerName]
        )
    }

    // MARK: - Generic REST sender

    private func sendNotification(toUserId: String, heading: String, content: String, data: [String: String]) {
        guard let url = URL(string: "https://api.onesignal.com/notifications") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "app_id":          oneSignalAppId,
            "headings":        ["en": heading],
            "contents":        ["en": content],
            "data":            data,
            "include_aliases": ["external_id": [toUserId]],
            "target_channel":  "push"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("❌ OneSignal push failed: \(error.localizedDescription)")
            } else if let http = response as? HTTPURLResponse {
                print("✅ OneSignal push sent — status: \(http.statusCode)")
            }
        }.resume()
    }
}

// MARK: - Notification click handler

extension PushNotificationManager: OSNotificationClickListener {
    func onClick(event: OSNotificationClickEvent) {
        let data     = event.notification.additionalData ?? [:]
        let action   = data["action"]      as? String ?? ""
        let trainerId = data["trainer_id"] as? String ?? ""
        let table    = data["table"]       as? String ?? ""
        let senderId = data["sender_id"]   as? String ?? ""

        NotificationCenter.default.post(
            name: .tmPushNotificationTapped,
            object: nil,
            userInfo: [
                "action":     action,
                "trainer_id": trainerId,
                "table":      table,
                "sender_id":  senderId
            ]
        )
    }
}

extension Notification.Name {
    static let tmPushNotificationTapped = Notification.Name("tmPushNotificationTapped")
}
