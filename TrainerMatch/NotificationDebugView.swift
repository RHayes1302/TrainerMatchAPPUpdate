//
//  NotificationDebugView.swift
//  TrainerMatch
//
//  Drop this view into any debug menu or settings page.
//  It verifies OneSignal login, sends a real test push to yourself,
//  and shows the full OneSignal API response so you can confirm
//  the pipeline is working end-to-end.
//

import SwiftUI
import OneSignalFramework

struct NotificationDebugView: View {

    @ObservedObject private var auth = SupabaseAuthManager.shared

    // Results
    @State private var onesignalUserId: String = "—"
    @State private var onesignalSubId:  String = "—"
    @State private var pushResponse:    String = ""
    @State private var isSending       = false
    @State private var logs:            [LogEntry] = []

    struct LogEntry: Identifiable {
        let id   = UUID()
        let time: Date
        let icon: String
        let text: String
    }

    // Computed: current user's auth UUID (what we pass to OneSignal.login)
    private var currentAuthId: String {
        if let t = auth.currentTrainer { return t.authId?.uuidString ?? t.id.uuidString }
        if let c = auth.currentClient  { return c.authId?.uuidString ?? c.id.uuidString }
        return "Not logged in"
    }

    private var currentRole: String {
        auth.currentUserRole == .trainer ? "Trainer" : "Client"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    Text("Notification Debug")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.tmGold)
                    Text("Verify OneSignal + push pipeline end-to-end")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))

                    divider

                    // ── Identity ──────────────────────────────────────────
                    sectionHeader("IDENTITY")

                    infoRow("Role",            currentRole)
                    infoRow("Supabase Auth ID", currentAuthId)
                    infoRow("OS External ID",  onesignalUserId)
                    infoRow("OS Sub ID",       onesignalSubId)

                    Button(action: checkIdentity) {
                        label("Check OneSignal Identity", icon: "person.badge.shield.checkmark")
                    }

                    divider

                    // ── Send test push ─────────────────────────────────────
                    sectionHeader("SEND TEST PUSH TO YOURSELF")
                    Text("This fires a real push to your own device using your auth ID as the external_id. If it arrives, the full pipeline works.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: sendTestPush) {
                        if isSending {
                            HStack { ProgressView().tint(.black); Text("Sending…") }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.tmGold.opacity(0.6))
                                .cornerRadius(10)
                        } else {
                            label("Send Test Push", icon: "paperplane.fill")
                        }
                    }
                    .disabled(isSending || currentAuthId == "Not logged in")

                    if !pushResponse.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("API RESPONSE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(.tmGold)
                            Text(pushResponse)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(pushResponse.contains("\"id\"") && !pushResponse.contains("\"id\":\"\"") ? .green : .red)
                                .padding(10)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }

                    divider

                    // ── Log ────────────────────────────────────────────────
                    if !logs.isEmpty {
                        sectionHeader("LOG")
                        ForEach(logs) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Text(entry.icon).font(.system(size: 13))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.text)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(entry.time, style: .time)
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        Button(action: { logs.removeAll() }) {
                            Text("Clear Log")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.7))
                        }
                        .padding(.top, 4)
                    }

                    // ── What to look for ──────────────────────────────────
                    divider
                    sectionHeader("WHAT TO LOOK FOR")
                    checklistItem("OS External ID matches your Supabase Auth ID", condition: onesignalUserId == currentAuthId && currentAuthId != "Not logged in")
                    checklistItem("OS Sub ID is not empty", condition: !onesignalSubId.isEmpty && onesignalSubId != "—")
                    checklistItem("API response contains a UUID (not empty string)", condition: pushResponse.contains("\"id\":\"") && !pushResponse.contains("\"id\":\"\""))
                    checklistItem("Push notification arrived on device", condition: false) // manual check

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
        .navigationTitle("Push Debug")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { checkIdentity() }
    }

    // MARK: - Actions

    private func checkIdentity() {
        let extId = OneSignal.User.externalId ?? "nil — OneSignal.login() not called yet"
        let subId = OneSignal.User.pushSubscription.id ?? "nil — not subscribed yet"
        onesignalUserId = extId
        onesignalSubId  = subId
        log("🔍", "External ID: \(extId)")
        log("📱", "Subscription ID: \(subId)")
        if extId == currentAuthId {
            log("✅", "External ID matches Supabase auth ID — login is correct")
        } else {
            log("❌", "External ID does NOT match auth ID. Make sure loginUser() is called after sign-in.")
        }
    }

    private func sendTestPush() {
        guard currentAuthId != "Not logged in" else { return }
        isSending = true
        pushResponse = ""
        log("🚀", "Sending test push to external_id: \(currentAuthId)")

        let oneSignalAppId = "0aedf585-a2ab-468a-89bf-115ba2f5eec6"
        let restApiKey     = "Key os_v2_app_blw7lbncvndivcn7cfn2f5poy2xi3nlgatcus5f6nrel2ewjlbmm4rtuvfq3wvrvp2sh2d55gvhbv4gicphau44qy4oaaw5zjwqy6sq"

        guard let url = URL(string: "https://api.onesignal.com/notifications") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(restApiKey,         forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "app_id":          oneSignalAppId,
            "target_channel":  "push",
            "headings":        ["en": "✅ TrainerMatch Debug"],
            "contents":        ["en": "Push pipeline working! external_id: \(currentAuthId.prefix(8))…"],
            "data":            ["action": "debug_test"],
            "include_aliases": ["external_id": [currentAuthId]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSending = false
                if let error = error {
                    pushResponse = "Network error: \(error.localizedDescription)"
                    log("❌", "Network error: \(error.localizedDescription)")
                    return
                }
                if let http = response as? HTTPURLResponse {
                    log("📡", "HTTP status: \(http.statusCode)")
                }
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    pushResponse = str
                    if str.contains("\"id\":\"\"") {
                        log("⚠️", "API returned empty ID — user not subscribed or external_id not found in OneSignal")
                    } else if str.contains("invalid_aliases") {
                        log("❌", "invalid_aliases — external_id not registered. Is OneSignal.login() being called?")
                    } else {
                        log("✅", "Push accepted by OneSignal — check your device")
                    }
                }
            }
        }.resume()
    }

    // MARK: - Logging

    private func log(_ icon: String, _ text: String) {
        logs.insert(LogEntry(time: Date(), icon: icon, text: text), at: 0)
    }

    // MARK: - Sub-views

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .tracking(1.5)
            .foregroundColor(.tmGold)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private func label(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title).fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.tmGold)
        .foregroundColor(.black)
        .cornerRadius(10)
    }

    private func checklistItem(_ text: String, condition: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: condition ? "checkmark.circle.fill" : "circle")
                .foregroundColor(condition ? .green : .white.opacity(0.25))
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(condition ? .white : .white.opacity(0.5))
        }
    }
}
