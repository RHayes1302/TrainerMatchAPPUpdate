//
//  PushNotificationManager.swift
//  TrainerMatch
//

import SwiftUI
import UserNotifications
import OneSignalFramework
import Supabase

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

        // Save the OneSignal subscription ID to Supabase
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let subId = OneSignal.User.pushSubscription.id {
                print("📱 OneSignal subscription ID: \(subId)")
                Task {
                    await self.saveSubscriptionId(subId, forUserId: userId)
                }
            }
        }
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

    // MARK: - Save subscription ID to Supabase

    private func saveSubscriptionId(_ subId: String, forUserId: String) async {
        struct Update: Encodable {
            let onesignalId: String
            enum CodingKeys: String, CodingKey {
                case onesignalId = "onesignal_id"
            }
        }
        try? await supabase.from("trainers")
            .update(Update(onesignalId: subId))
            .eq("auth_id", value: forUserId)
            .execute()
        try? await supabase.from("clients")
            .update(Update(onesignalId: subId))
            .eq("auth_id", value: forUserId)
            .execute()
        print("✅ Saved OneSignal ID to Supabase: \(subId)")
    }

    // MARK: - New client selected trainer

    func sendNewClientNotification(toTrainerId: String, clientName: String) {
        print("🔔 Sending new client push to trainerId: \(toTrainerId)")
        sendNotification(
            toUserId: toTrainerId,
            heading:  "New Training Request! 💪",
            content:  "\(clientName) wants you as their trainer. Tap to review.",
            data:     ["action": "pending_requests", "trainer_id": toTrainerId]
        )
    }

    // MARK: - Trainer accepted client

    func sendTrainerAcceptedNotification(toClientId: String, trainerName: String) {
        print("🔔 Sending accepted push to clientId: \(toClientId)")
        sendNotification(
            toUserId: toClientId,
            heading:  "\(trainerName) accepted you! 🎉",
            content:  "You're now connected. Please complete your PAR-Q health form.",
            data:     ["action": "parq_prompt", "trainer_name": trainerName]
        )
    }

    // MARK: - Chat message notification

    func sendMessageNotification(toUserId: String, senderName: String, preview: String) {
        print("🔔 Sending message push to: \(toUserId)")
        sendNotification(
            toUserId: toUserId,
            heading:  "New message from \(senderName)",
            content:  preview.isEmpty ? "Sent you a message" : preview,
            data:     ["action": "open_chat", "sender_id": toUserId]
        )
    }
    func sendVideoMessageNotification(toClientId: String, trainerName: String) {
        print("🔔 Sending video message push to clientId: \(toClientId)")
        Task {
            // Look up by client id column, not auth_id
            struct Row: Decodable {
                let onesignalId: String?
                enum CodingKeys: String, CodingKey {
                    case onesignalId = "onesignal_id"
                }
            }
            if let row = try? await supabase.from("clients")
                .select("onesignal_id")
                .eq("id", value: toClientId)
                .single()
                .execute()
                .value as Row,
               let subId = row.onesignalId {
                print("✅ Found client onesignal_id: \(subId)")
                sendPush(
                    toSubscriptionId: subId,
                    heading:  "Your Trainer sent a video 🎥",
                    content:  "Tap to view the video message from \(trainerName).",
                    data:     ["action": "open_videos", "trainer_name": trainerName]
                )
            } else {
                print("❌ No OneSignal ID found for clientId: \(toClientId)")
            }
        }
    }    // MARK: - Generic sender — fetches subscription ID then sends

    private func sendNotification(
        toUserId: String,
        heading:  String,
        content:  String,
        data:     [String: String]
    ) {
        Task {
            let subId = await fetchOneSignalId(forUserId: toUserId)
            guard let subId = subId else {
                print("❌ No OneSignal subscription ID found for user: \(toUserId)")
                return
            }
            sendPush(toSubscriptionId: subId, heading: heading, content: content, data: data)
        }
    }

    // MARK: - Fetch OneSignal subscription ID from Supabase

    private func fetchOneSignalId(forUserId: String) async -> String? {
        struct Row: Decodable {
            let onesignalId: String?
            enum CodingKeys: String, CodingKey {
                case onesignalId = "onesignal_id"
            }
        }
        // Try trainer
        if let row = try? await supabase.from("trainers")
            .select("onesignal_id")
            .eq("auth_id", value: forUserId)
            .single()
            .execute()
            .value as Row,
           let id = row.onesignalId {
            print("✅ Found trainer onesignal_id: \(id)")
            return id
        }
        // Try client
        if let row = try? await supabase.from("clients")
            .select("onesignal_id")
            .eq("auth_id", value: forUserId)
            .single()
            .execute()
            .value as Row,
           let id = row.onesignalId {
            print("✅ Found client onesignal_id: \(id)")
            return id
        }
        return nil
    }

    // MARK: - Send push via OneSignal REST API

    private func sendPush(
        toSubscriptionId: String,
        heading:          String,
        content:          String,
        data:             [String: String]
    ) {
        guard let url = URL(string: "https://api.onesignal.com/notifications") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(
            "Key os_v2_app_blw7lbncvndivcn7cfn2f5poy2xi3nlgatcus5f6nrel2ewjlbmm4rtuvfq3wvrvp2sh2d55gvhbv4gicphau44qy4oaaw5zjwqy6sq",
            forHTTPHeaderField: "Authorization"
        )

        let body: [String: Any] = [
            "app_id":                   oneSignalAppId,
            "headings":                 ["en": heading],
            "contents":                 ["en": content],
            "data":                     data,
            "include_subscription_ids": [toSubscriptionId],
            "target_channel":           "push"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ OneSignal push failed: \(error.localizedDescription)")
            } else if let http = response as? HTTPURLResponse {
                print("✅ OneSignal push sent — status: \(http.statusCode)")
                if let data = data,
                   let str = String(data: data, encoding: .utf8) {
                    print("OneSignal response: \(str)")
                }
            }
        }.resume()
    }

} // ← closes the class

// MARK: - Notification click handler

extension PushNotificationManager: OSNotificationClickListener {
    func onClick(event: OSNotificationClickEvent) {
        let data      = event.notification.additionalData ?? [:]
        let action    = data["action"]     as? String ?? ""
        let trainerId = data["trainer_id"] as? String ?? ""
        let table     = data["table"]      as? String ?? ""
        let senderId  = data["sender_id"]  as? String ?? ""

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
