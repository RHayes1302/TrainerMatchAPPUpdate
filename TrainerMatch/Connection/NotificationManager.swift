//
//  NotificationManager.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 3/8/26.
//

//
//  NotificationManager.swift
//  TrainerMatch
//
//  Central notification manager for all trainer ↔ client communication.
//  Handles permission request, scheduling local notifications, and
//  an in-app notification inbox for both trainers and clients.
//

import SwiftUI
import UserNotifications

// MARK: - Notification Category

enum TMNotificationCategory: String, Codable, CaseIterable {
    case message       = "Message"
    case video         = "Video"
    case file          = "File"
    case appointment   = "Appointment"
    case appointmentAccepted = "Appointment Accepted"
    case appointmentDeclined = "Appointment Declined"
    case checkIn       = "Check-In"
    case weight        = "Weight Log"
    case release       = "Trainer Released"

    var icon: String {
        switch self {
        case .message:             return "bubble.left.fill"
        case .video:               return "video.fill"
        case .file:                return "doc.fill"
        case .appointment:         return "calendar.badge.plus"
        case .appointmentAccepted: return "calendar.badge.checkmark"
        case .appointmentDeclined: return "calendar.badge.minus"
        case .checkIn:             return "figure.run"
        case .weight:              return "scalemass.fill"
        case .release:             return "person.fill.xmark"
        }
    }

    var color: Color {
        switch self {
        case .message:             return .tmGold
        case .video:               return .purple
        case .file:                return .blue
        case .appointment:         return .orange
        case .appointmentAccepted: return .green
        case .appointmentDeclined: return Color(red: 0.9, green: 0.2, blue: 0.2)
        case .checkIn:             return .cyan
        case .weight:              return .tmGold
        case .release:             return Color(red: 0.9, green: 0.2, blue: 0.2)
        }
    }
}

// MARK: - In-App Notification Model

struct TMNotification: Identifiable, Codable {
    let id: String
    let recipientId: String          // trainerId or clientId
    let recipientRole: RecipientRole
    let senderId: String
    let senderName: String
    let category: TMNotificationCategory
    let title: String
    let body: String
    let date: Date
    var isRead: Bool

    enum RecipientRole: String, Codable {
        case trainer, client
    }

    init(recipientId: String, recipientRole: RecipientRole,
         senderId: String, senderName: String,
         category: TMNotificationCategory, title: String, body: String) {
        self.id            = UUID().uuidString
        self.recipientId   = recipientId
        self.recipientRole = recipientRole
        self.senderId      = senderId
        self.senderName    = senderName
        self.category      = category
        self.title         = title
        self.body          = body
        self.date          = Date()
        self.isRead        = false
    }
}

// MARK: - NotificationManager

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var notifications: [TMNotification] = []

    private var storeURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("tmNotifications.json")
    }

    private init() { load() }

    // MARK: - Permission

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, _ in
            print("Notification permission: \(granted)")
        }
    }

    // MARK: - Send

    func send(
        recipientId: String,
        recipientRole: TMNotification.RecipientRole,
        senderId: String,
        senderName: String,
        category: TMNotificationCategory,
        title: String,
        body: String
    ) {
        let n = TMNotification(
            recipientId: recipientId,
            recipientRole: recipientRole,
            senderId: senderId,
            senderName: senderName,
            category: category,
            title: title,
            body: body
        )
        notifications.insert(n, at: 0)
        save()
        scheduleLocalNotification(title: title, body: body, category: category)
    }

    // Convenience helpers for each event type

    func notifyMessage(to recipientId: String, role: TMNotification.RecipientRole,
                       from senderId: String, senderName: String, preview: String) {
        send(recipientId: recipientId, recipientRole: role,
             senderId: senderId, senderName: senderName,
             category: .message,
             title: "New message from \(senderName)",
             body: preview.isEmpty ? "Sent you a message" : preview)
    }

    func notifyVideo(to recipientId: String, role: TMNotification.RecipientRole,
                     from senderId: String, senderName: String) {
        send(recipientId: recipientId, recipientRole: role,
             senderId: senderId, senderName: senderName,
             category: .video,
             title: "\(senderName) sent a video",
             body: "Tap to view the video message")
    }

    func notifyFile(to recipientId: String, role: TMNotification.RecipientRole,
                    from senderId: String, senderName: String, fileName: String) {
        send(recipientId: recipientId, recipientRole: role,
             senderId: senderId, senderName: senderName,
             category: .file,
             title: "\(senderName) shared a file",
             body: fileName)
    }

    func notifyAppointmentRequest(to trainerId: String, from clientId: String,
                                  clientName: String, sessionTitle: String, date: Date) {
        let df = DateFormatter(); df.dateFormat = "EEE, MMM d 'at' h:mm a"
        send(recipientId: trainerId, recipientRole: .trainer,
             senderId: clientId, senderName: clientName,
             category: .appointment,
             title: "\(clientName) requested a session",
             body: "\(sessionTitle) · \(df.string(from: date))")
    }

    func notifyAppointmentAccepted(to clientId: String, from trainerId: String,
                                   trainerName: String, sessionTitle: String, date: Date) {
        let df = DateFormatter(); df.dateFormat = "EEE, MMM d 'at' h:mm a"
        send(recipientId: clientId, recipientRole: .client,
             senderId: trainerId, senderName: trainerName,
             category: .appointmentAccepted,
             title: "\(trainerName) accepted your session",
             body: "\(sessionTitle) · \(df.string(from: date))")
    }

    func notifyAppointmentDeclined(to clientId: String, from trainerId: String,
                                   trainerName: String, sessionTitle: String) {
        send(recipientId: clientId, recipientRole: .client,
             senderId: trainerId, senderName: trainerName,
             category: .appointmentDeclined,
             title: "\(trainerName) declined your session request",
             body: sessionTitle)
    }

    func notifyWeightLogged(to clientId: String, from trainerId: String,
                            trainerName: String, weight: String) {
        send(recipientId: clientId, recipientRole: .client,
             senderId: trainerId, senderName: trainerName,
             category: .weight,
             title: "\(trainerName) logged your weight",
             body: weight)
    }

    func notifyCheckIn(to trainerId: String, from clientId: String,
                       clientName: String, note: String) {
        send(recipientId: trainerId, recipientRole: .trainer,
             senderId: clientId, senderName: clientName,
             category: .checkIn,
             title: "\(clientName) checked in",
             body: note.isEmpty ? "Sent a check-in" : note)
    }

    func notifyRelease(to trainerId: String, from clientId: String, clientName: String) {
        send(recipientId: trainerId, recipientRole: .trainer,
             senderId: clientId, senderName: clientName,
             category: .release,
             title: "\(clientName) released you as their trainer",
             body: "Your connection with \(clientName) has ended")
    }

    // MARK: - Queries

    func notifications(for recipientId: String) -> [TMNotification] {
        notifications.filter { $0.recipientId == recipientId }
    }

    func unreadCount(for recipientId: String) -> Int {
        notifications.filter { $0.recipientId == recipientId && !$0.isRead }.count
    }

    func markRead(_ notification: TMNotification) {
        if let i = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[i].isRead = true
            save()
        }
    }

    func markAllRead(for recipientId: String) {
        for i in notifications.indices where notifications[i].recipientId == recipientId {
            notifications[i].isRead = true
        }
        save()
    }

    func delete(_ notification: TMNotification) {
        notifications.removeAll { $0.id == notification.id }
        save()
    }

    // MARK: - Local Push

    private func scheduleLocalNotification(title: String, body: String,
                                           category: TMNotificationCategory) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        content.badge = 1
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Persistence

    private func save() {
        try? JSONEncoder().encode(notifications).write(to: storeURL)
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storeURL.path),
              let data = try? Data(contentsOf: storeURL),
              let saved = try? JSONDecoder().decode([TMNotification].self, from: data)
        else { return }
        notifications = saved
    }
}

// MARK: - Notification Inbox View (shared by trainer & client)

struct TMNotificationInboxView: View {
    let recipientId: String
    let role: TMNotification.RecipientRole
    @ObservedObject private var manager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss

    private var items: [TMNotification] { manager.notifications(for: recipientId) }
    private var unread: [TMNotification] { items.filter { !$0.isRead } }
    private var read:   [TMNotification] { items.filter {  $0.isRead } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if items.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 48)).foregroundColor(.white.opacity(0.12))
                        .padding(.top, 60)
                    Text("No notifications yet")
                        .font(.title3).fontWeight(.bold).foregroundColor(.white.opacity(0.4))
                    Text("Messages, files, appointments, videos and more will appear here.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.25))
                        .multilineTextAlignment(.center).padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    if !unread.isEmpty {
                        Section {
                            ForEach(unread) { n in
                                TMNotificationRow(notification: n)
                                    .listRowBackground(n.category.color.opacity(0.07))
                                    .listRowSeparatorTint(Color.white.opacity(0.06))
                                    .onTapGesture { manager.markRead(n) }
                                    .swipeActions { Button("Delete", role: .destructive) { manager.delete(n) } }
                            }
                        } header: {
                            Text("NEW — \(unread.count)")
                                .font(.system(size: 10, weight: .bold)).tracking(1.5)
                                .foregroundColor(.tmGold)
                        }
                    }
                    if !read.isEmpty {
                        Section {
                            ForEach(read) { n in
                                TMNotificationRow(notification: n)
                                    .listRowBackground(Color.white.opacity(0.02))
                                    .listRowSeparatorTint(Color.white.opacity(0.04))
                                    .swipeActions { Button("Delete", role: .destructive) { manager.delete(n) } }
                            }
                        } header: {
                            Text("EARLIER")
                                .font(.system(size: 10, weight: .bold)).tracking(1.5)
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").fontWeight(.semibold)
                        Text("Back")
                    }.foregroundColor(.tmGold)
                }
            }
            if !unread.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Mark All Read") { manager.markAllRead(for: recipientId) }
                        .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                }
            }
        }
        .onAppear { manager.markAllRead(for: recipientId) }
    }
}

struct TMNotificationRow: View {
    let notification: TMNotification

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(notification.category.color.opacity(notification.isRead ? 0.1 : 0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: notification.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(notification.isRead
                                     ? notification.category.color.opacity(0.5)
                                     : notification.category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 14, weight: notification.isRead ? .regular : .semibold))
                    .foregroundColor(notification.isRead ? .white.opacity(0.6) : .white)
                    .lineLimit(2)
                Text(notification.body)
                    .font(.caption).foregroundColor(.white.opacity(0.4)).lineLimit(1)
                Text(notification.date, style: .relative)
                    .font(.caption2).foregroundColor(.white.opacity(0.3))
            }

            Spacer()

            if !notification.isRead {
                Circle().fill(notification.category.color).frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Bell Button (reusable for both trainer & client toolbars)

struct TMBellButton: View {
    let recipientId: String
    let role: TMNotification.RecipientRole
    @ObservedObject private var manager = NotificationManager.shared
    @State private var showingInbox = false

    private var count: Int { manager.unreadCount(for: recipientId) }

    var body: some View {
        Button(action: { showingInbox = true }) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .foregroundColor(count > 0 ? .tmGold : .white.opacity(0.45))
                    .font(.system(size: 17))
                if count > 0 {
                    ZStack {
                        Circle().fill(Color.red).frame(width: 16, height: 16)
                        Text(count > 9 ? "9+" : "\(count)")
                            .font(.system(size: 9, weight: .black)).foregroundColor(.white)
                    }
                    .offset(x: 8, y: -8)
                }
            }
        }
        .sheet(isPresented: $showingInbox) {
            NavigationView {
                TMNotificationInboxView(recipientId: recipientId, role: role)
            }
            .tint(.tmGold)
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
