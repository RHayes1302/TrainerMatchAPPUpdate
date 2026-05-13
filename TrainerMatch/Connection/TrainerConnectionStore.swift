//
//  TrainerConnectionStore.swift
//  TrainerMatch
//

import SwiftUI
import Combine

// MARK: - Models

struct TrainerRequest: Codable, Identifiable {
    let id: String
    let trainerId: String
    let clientId: String
    let clientName: String
    let clientEmail: String
    let message: String
    let sentAt: Date
    var status: RequestStatus

    enum RequestStatus: String, Codable {
        case pending  = "Pending"
        case accepted = "Accepted"
        case declined = "Declined"
    }
}

struct TrainerClientConnection: Codable, Identifiable {
    let id: String
    let trainerId: String
    let clientId: String
    let clientName: String
    let trainerName: String
    let connectedAt: Date
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let connectionId: String
    let senderId: String
    let senderName: String
    let text: String
    let sentAt: Date
    var isRead: Bool
}

// MARK: - Store

class TrainerConnectionStore: ObservableObject {
    static let shared = TrainerConnectionStore()

    @Published var requests:    [TrainerRequest]          = []
    @Published var connections: [TrainerClientConnection] = []
    @Published var messages:    [ChatMessage]             = []

    private let requestsKey    = "tm_requests"
    private let connectionsKey = "tm_connections"
    private let messagesKey    = "tm_messages"

    private init() { load() }

    // MARK: - Persistence

    private func load() {
        requests    = decode([TrainerRequest].self,          forKey: requestsKey)    ?? []
        connections = decode([TrainerClientConnection].self, forKey: connectionsKey) ?? []
        messages    = decode([ChatMessage].self,             forKey: messagesKey)    ?? []
    }

    func save() {
        encode(requests,    forKey: requestsKey)
        encode(connections, forKey: connectionsKey)
        encode(messages,    forKey: messagesKey)
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: - Requests (Supabase backed)

    func sendRequest(from client: SavedClientProfile, to trainer: SavedTrainerProfile, message: String) {
        Task {
            try? await SBConnectionStore.shared.sendRequest(
                trainerId:   trainer.id,
                trainerName: trainer.firstName + " " + trainer.lastName,
                clientId:    client.id,
                clientName:  client.fullName,
                clientEmail: client.email,
                message:     message
            )
        }
    }

    func acceptRequest(_ request: TrainerRequest, trainerName: String) {
        Task {
            try? await SBConnectionStore.shared.acceptRequest(request.id, trainerName: trainerName)
        }
    }

    func declineRequest(_ request: TrainerRequest) {
        Task {
            try? await SBConnectionStore.shared.declineRequest(request.id)
        }
    }

    func releaseConnection(id: String) {
        Task {
            try? await SBConnectionStore.shared.releaseConnection(id)
        }
        connections.removeAll { $0.id == id }
        messages.removeAll { $0.connectionId == id }
        save()
    }

    func notifyTrainerOfRelease(trainerId: String, trainerName: String, clientName: String) {
        let notification = ReleaseNotification(
            trainerId:   trainerId,
            trainerName: trainerName,
            clientName:  clientName
        )
        var saved = ReleaseNotification.load()
        saved.insert(notification, at: 0)
        ReleaseNotification.save(saved)
        NotificationManager.shared.notifyRelease(
            to: trainerId, from: "client", clientName: clientName
        )
    }

    // MARK: - Queries (read from synced local arrays)

        func pendingRequests(forTrainer trainerId: String) -> [TrainerRequest] {
            requests.filter { $0.trainerId == trainerId && $0.status == .pending }
        }

        func activeClients(forTrainer trainerId: String) -> [TrainerClientConnection] {
            connections.filter { $0.trainerId == trainerId }
        }

        func myTrainers(forClient clientId: String) -> [TrainerClientConnection] {
            connections.filter { $0.clientId == clientId }
        }

        func connection(trainerId: String, clientId: String) -> TrainerClientConnection? {
            connections.first { $0.trainerId == trainerId && $0.clientId == clientId }
        }

        func requestStatus(trainerId: String, clientId: String) -> TrainerRequest.RequestStatus? {
            requests.last { $0.trainerId == trainerId && $0.clientId == clientId }?.status
        }

    // MARK: - Messages (local)

    func sendMessage(connectionId: String, senderId: String, senderName: String, text: String) {
        let msg = ChatMessage(
            id:           UUID().uuidString,
            connectionId: connectionId,
            senderId:     senderId,
            senderName:   senderName,
            text:         text,
            sentAt:       Date(),
            isRead:       false
        )
        messages.append(msg)
        save()
        objectWillChange.send()

        if let conn = connections.first(where: { $0.id == connectionId }) {
            let recipientId   = senderId == conn.trainerId ? conn.clientId : conn.trainerId
            let recipientRole: TMNotification.RecipientRole = senderId == conn.trainerId ? .client : .trainer
            NotificationManager.shared.notifyMessage(
                to:         recipientId,
                role:       recipientRole,
                from:       senderId,
                senderName: senderName,
                preview:    text
            )
        }
    }

    func messages(forConnection connectionId: String) -> [ChatMessage] {
        messages.filter { $0.connectionId == connectionId }.sorted { $0.sentAt < $1.sentAt }
    }

    func unreadCount(forConnection connectionId: String, currentUserId: String) -> Int {
        messages.filter {
            $0.connectionId == connectionId &&
            $0.senderId     != currentUserId &&
            !$0.isRead
        }.count
    }

    func markRead(connectionId: String, currentUserId: String) {
        for i in messages.indices {
            if messages[i].connectionId == connectionId &&
               messages[i].senderId     != currentUserId {
                messages[i].isRead = true
            }
        }
        save()
    }
}

// MARK: - Trainer Request Button

struct TrainerRequestButton: View {
    let trainer: SavedTrainerProfile
    @ObservedObject private var store       = TrainerConnectionStore.shared
    @ObservedObject private var sbStore     = SBConnectionStore.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var message      = ""
    @State private var justSent     = false
    @State private var showingLogin  = false
    @State private var showingSignup = false

    private var clientId:   String? { authManager.currentClientProfile?.id }
    private var clientName: String  { authManager.currentClientProfile?.fullName ?? "" }

    private var status: TrainerRequest.RequestStatus? {
        guard let cid = clientId else { return nil }
        return store.requestStatus(trainerId: trainer.id, clientId: cid)
    }

    private var connection: TrainerClientConnection? {
        guard let cid = clientId else { return nil }
        return store.connection(trainerId: trainer.id, clientId: cid)
    }

    var body: some View {
        VStack(spacing: 16) {
            if let conn = connection {
                NavigationLink(destination: SupabaseChatView(
                    trainerId:       UUID(uuidString: conn.trainerId) ?? UUID(),
                    clientId:        UUID(uuidString: conn.clientId)  ?? UUID(),
                    currentUserId:   UUID(uuidString: clientId ?? "") ?? UUID(),
                    currentUserName: clientName,
                    otherPersonName: trainer.firstName
                )) {
                    HStack(spacing: 10) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                        Text("MESSAGE \(trainer.firstName.uppercased())")
                            .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 27).fill(Color.tmGold)
                        .shadow(color: Color.tmGold.opacity(0.4), radius: 10, y: 5))
                }
                .buttonStyle(.plain)

                Text("You're connected with \(trainer.firstName)!")
                    .font(.caption).foregroundColor(.tmGold).multilineTextAlignment(.center)

            } else if status == .pending {
                HStack(spacing: 10) {
                    Image(systemName: "clock.fill")
                    Text("REQUEST SENT")
                        .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                }
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(RoundedRectangle(cornerRadius: 27)
                    .fill(Color.white.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 27)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)))
                Text("Waiting for \(trainer.firstName) to accept your request.")
                    .font(.caption).foregroundColor(.white.opacity(0.5)).multilineTextAlignment(.center)

            } else if status == .declined {
                VStack(spacing: 8) {
                    Text("Request Declined")
                        .font(.headline).foregroundColor(.white.opacity(0.5))
                    Text("\(trainer.firstName) is not available at this time.")
                        .font(.caption).foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center)
                }
                .padding().frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04)))

            } else if clientId == nil {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 40)).foregroundColor(.tmGold.opacity(0.7))
                        Text("Want to train with \(trainer.firstName)?")
                            .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Text("Log in or create a free client account to send a request.")
                            .font(.subheadline).foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center).lineSpacing(3)
                    }
                    .padding(.top, 8)

                    Button(action: { showingLogin = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("LOG IN").font(.system(size: 15, weight: .heavy)).tracking(0.5)
                        }
                        .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 26).fill(Color.tmGold)
                            .shadow(color: Color.tmGold.opacity(0.4), radius: 10, y: 5))
                    }

                    Button(action: { showingSignup = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                            Text("CREATE FREE ACCOUNT")
                                .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                        }
                        .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 26).fill(Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: 26)
                                .stroke(Color.tmGold, lineWidth: 2)))
                    }
                }
                .padding(.vertical, 8)
                .sheet(isPresented: $showingLogin) {
                    LoginView().environmentObject(AuthManager.shared)
                }
                .sheet(isPresented: $showingSignup) {
                    NavigationView {
                        ClientSignupView().environmentObject(AuthManager.shared)
                    }
                }

            } else {
                VStack(spacing: 14) {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $message)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(.white).accentColor(.tmGold).padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.07)))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1))
                        if message.isEmpty {
                            Text("Hi \(trainer.firstName), I'm interested in training with you...")
                                .foregroundColor(.white.opacity(0.25)).font(.body)
                                .padding(.top, 18).padding(.leading, 14).allowsHitTesting(false)
                        }
                    }
                    Button(action: sendRequest) {
                        HStack(spacing: 8) {
                            Image(systemName: justSent ? "checkmark.circle.fill" : "paperplane.fill")
                            Text(justSent ? "REQUEST SENT!" : "REQUEST THIS TRAINER")
                                .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                        }
                        .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 27)
                            .fill(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                  ? Color.gray.opacity(0.4) : Color.tmGold)
                            .shadow(color: message.isEmpty ? .clear : Color.tmGold.opacity(0.4),
                                    radius: 10, y: 5))
                    }
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            if let cid = clientId {
                SBConnectionStore.shared.loadForClient(cid)
            }
        }
    }

    private func sendRequest() {
        guard let client = authManager.currentClientProfile else { return }
        store.sendRequest(from: client, to: trainer, message: message)
        message = ""; justSent = true
    }
}

// MARK: - Trainer Clients Tab

struct TrainerClientsTab: View {
    let trainerId:     String
    let trainerName:   String
    let currentUserId: String
    @ObservedObject private var store   = TrainerConnectionStore.shared
    @ObservedObject private var sbStore = SBConnectionStore.shared
    @State private var selectedConnection: TrainerClientConnection?

    private var pending: [TrainerRequest] {
        store.pendingRequests(forTrainer: trainerId)
    }
    private var activeClients: [TrainerClientConnection] {
        store.activeClients(forTrainer: trainerId)
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 0) {
                statPill("\(activeClients.count)", label: "Active Clients", icon: "person.2.fill")
                Divider().background(Color.white.opacity(0.1)).frame(height: 40)
                statPill("\(pending.count)", label: "Pending", icon: "clock.fill")
            }
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)))

            if !pending.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("PENDING REQUESTS", icon: "clock.fill", count: pending.count)
                    ForEach(pending) { req in
                        PendingRequestCard(request: req, trainerName: trainerName)
                    }
                }
            }

            if activeClients.isEmpty && pending.isEmpty {
                emptyState
            } else if !activeClients.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("MY CLIENTS", icon: "person.2.fill", count: activeClients.count)
                    ForEach(activeClients) { conn in
                        Button(action: { selectedConnection = conn }) {
                            ActiveClientCard(connection: conn, currentUserId: currentUserId)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 40)
        .onAppear {
            SBConnectionStore.shared.loadForTrainer(trainerId)
        }
        .sheet(item: $selectedConnection) { conn in
            NavigationView {
                SupabaseChatView(
                    trainerId:       UUID(uuidString: conn.trainerId) ?? UUID(),
                    clientId:        UUID(uuidString: conn.clientId)  ?? UUID(),
                    currentUserId:   UUID(uuidString: currentUserId)  ?? UUID(),
                    currentUserName: trainerName,
                    otherPersonName: conn.clientName
                )
            }
            .tint(.tmGold)
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private func sectionHeader(_ title: String, icon: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.caption).foregroundColor(.tmGold)
            Text(title).font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
            Spacer()
            Text("\(count)").font(.caption).fontWeight(.bold).foregroundColor(.white.opacity(0.4))
        }
    }

    private func statPill(_ value: String, label: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(.tmGold).font(.subheadline)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 20, weight: .black)).foregroundColor(.white)
                Text(label).font(.system(size: 9, weight: .semibold)).tracking(0.5)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48)).foregroundColor(.tmGold.opacity(0.3)).padding(.top, 40)
            Text("No clients yet").font(.title3).fontWeight(.bold).foregroundColor(.white)
            Text("Once clients request to train with you, they'll appear here.")
                .font(.subheadline).foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center).padding(.horizontal, 30)
        }
    }
}

// MARK: - Pending Request Card

struct PendingRequestCard: View {
    let request:     TrainerRequest
    let trainerName: String
    @ObservedObject private var store = TrainerConnectionStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(LinearGradient(colors: [.tmGold, .tmGoldDark],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                    .overlay(Text(request.clientName.prefix(1))
                        .font(.headline).fontWeight(.bold).foregroundColor(.black))
                VStack(alignment: .leading, spacing: 3) {
                    Text(request.clientName)
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text(request.clientEmail).font(.caption).foregroundColor(.white.opacity(0.5))
                    Text(request.sentAt.formatted(.relative(presentation: .named)))
                        .font(.caption2).foregroundColor(.white.opacity(0.35))
                }
                Spacer()
                Image(systemName: "clock.fill").foregroundColor(.tmGold.opacity(0.7))
            }

            if !request.message.isEmpty {
                Text("\"\(request.message)\"")
                    .font(.subheadline).italic().foregroundColor(.white.opacity(0.65))
                    .lineLimit(3).padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
            }

            HStack(spacing: 12) {
                Button(action: { store.declineRequest(request) }) {
                    Text("DECLINE").font(.system(size: 12, weight: .heavy)).tracking(0.5)
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)))
                }
                Button(action: { store.acceptRequest(request, trainerName: trainerName) }) {
                    Text("ACCEPT").font(.system(size: 12, weight: .heavy)).tracking(0.5)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.tmGold)
                            .shadow(color: Color.tmGold.opacity(0.4), radius: 8, y: 4))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(Color.tmGold.opacity(0.2), lineWidth: 1)))
    }
}

// MARK: - Active Client Card

struct ActiveClientCard: View {
    let connection:    TrainerClientConnection
    let currentUserId: String
    @ObservedObject private var store = TrainerConnectionStore.shared

    private var unread: Int {
        store.unreadCount(forConnection: connection.id, currentUserId: currentUserId)
    }

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(LinearGradient(colors: [.tmGold, .tmGoldDark],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 52, height: 52)
                .overlay(Text(connection.clientName.prefix(1))
                    .font(.title3).fontWeight(.bold).foregroundColor(.black))
                .overlay(alignment: .topTrailing) {
                    if unread > 0 {
                        Circle().fill(Color.red).frame(width: 18, height: 18)
                            .overlay(Text("\(unread)").font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white))
                            .offset(x: 4, y: -4)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(connection.clientName)
                    .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                if let last = store.messages(forConnection: connection.id).last {
                    Text(last.text).font(.caption).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                } else {
                    Text("Tap to start chatting").font(.caption).foregroundColor(.white.opacity(0.35))
                }
                Text("Connected \(connection.connectedAt.formatted(.relative(presentation: .named)))")
                    .font(.caption2).foregroundColor(.white.opacity(0.3))
            }
            Spacer()
            Image(systemName: "bubble.left.fill").foregroundColor(.tmGold.opacity(0.6))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(Color.tmGold.opacity(0.15), lineWidth: 1)))
    }
}

// MARK: - My Trainers Section

struct MyTrainersSection: View {
    let clientId:   String
    let clientName: String
    @ObservedObject private var store   = TrainerConnectionStore.shared
    @ObservedObject private var sbStore = SBConnectionStore.shared

    private var myTrainers: [TrainerClientConnection] {
        store.myTrainers(forClient: clientId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !myTrainers.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill.checkmark").foregroundColor(.tmGold).font(.caption)
                    Text("MY TRAINERS").font(.system(size: 11, weight: .bold)).tracking(1.2)
                        .foregroundColor(.tmGold)
                }
                ForEach(myTrainers) { conn in
                    NavigationLink(destination: SupabaseChatView(
                        trainerId:       UUID(uuidString: conn.trainerId) ?? UUID(),
                        clientId:        UUID(uuidString: conn.clientId)  ?? UUID(),
                        currentUserId:   UUID(uuidString: clientId)        ?? UUID(),
                        currentUserName: clientName,
                        otherPersonName: conn.trainerName
                    )) {
                        ActiveClientCard(connection: conn, currentUserId: clientId)
                    }
                    .buttonStyle(.plain)
                }
                Divider().background(Color.white.opacity(0.08)).padding(.vertical, 4)
            }
        }
        .onAppear {
            SBConnectionStore.shared.loadForClient(clientId)
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let clientReleasedTrainer = Notification.Name("clientReleasedTrainer")
}

// MARK: - Release Notification Model

struct ReleaseNotification: Identifiable, Codable {
    let id:          String
    let trainerId:   String
    let trainerName: String
    let clientName:  String
    let date:        Date
    var isRead:      Bool

    init(trainerId: String, trainerName: String, clientName: String) {
        self.id          = UUID().uuidString
        self.trainerId   = trainerId
        self.trainerName = trainerName
        self.clientName  = clientName
        self.date        = Date()
        self.isRead      = false
    }

    private static var storeURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("releaseNotifications.json")
    }

    static func load() -> [ReleaseNotification] {
        guard let data = try? Data(contentsOf: storeURL),
              let saved = try? JSONDecoder().decode([ReleaseNotification].self, from: data)
        else { return [] }
        return saved
    }

    static func save(_ items: [ReleaseNotification]) {
        try? JSONEncoder().encode(items).write(to: storeURL)
    }
}

// MARK: - Trainer Release Notifications View

struct TrainerReleaseNotificationsView: View {
    let trainerId: String
    @State private var notifications: [ReleaseNotification] = []
    @Environment(\.dismiss) var dismiss

    private var unread: [ReleaseNotification] { notifications.filter { !$0.isRead } }
    private var read:   [ReleaseNotification] { notifications.filter {  $0.isRead } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Group {
                if notifications.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 44)).foregroundColor(.white.opacity(0.15)).padding(.top, 60)
                        Text("No notifications").font(.title3).foregroundColor(.white.opacity(0.4))
                        Text("You'll be notified here when a client releases you as their trainer.")
                            .font(.subheadline).foregroundColor(.white.opacity(0.3))
                            .multilineTextAlignment(.center).padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        if !unread.isEmpty {
                            Section {
                                ForEach(unread) { n in
                                    ReleaseNotificationRow(notification: n)
                                        .listRowBackground(Color.red.opacity(0.06))
                                        .listRowSeparatorTint(Color.white.opacity(0.07))
                                }
                            } header: {
                                Text("NEW").font(.system(size: 10, weight: .bold)).tracking(1.5)
                                    .foregroundColor(.red)
                            }
                        }
                        if !read.isEmpty {
                            Section {
                                ForEach(read) { n in
                                    ReleaseNotificationRow(notification: n)
                                        .listRowBackground(Color.white.opacity(0.03))
                                        .listRowSeparatorTint(Color.white.opacity(0.05))
                                }
                            } header: {
                                Text("EARLIER").font(.system(size: 10, weight: .bold)).tracking(1.5)
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                    }
                    .listStyle(.insetGrouped).scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Notifications").navigationBarTitleDisplayMode(.inline)
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
                    Button("Mark All Read") { markAllRead() }
                        .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                }
            }
        }
        .onAppear { loadNotifications() }
        .onReceive(NotificationCenter.default.publisher(for: .clientReleasedTrainer)) { _ in
            loadNotifications()
        }
    }

    private func loadNotifications() {
        notifications = ReleaseNotification.load().filter { $0.trainerId == trainerId }
        markAllRead()
    }

    private func markAllRead() {
        var all = ReleaseNotification.load()
        for i in all.indices where all[i].trainerId == trainerId { all[i].isRead = true }
        ReleaseNotification.save(all)
        notifications = all.filter { $0.trainerId == trainerId }
    }
}

struct ReleaseNotificationRow: View {
    let notification: ReleaseNotification

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(notification.isRead ? Color.white.opacity(0.08) : Color.red.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: "person.fill.xmark").font(.system(size: 15))
                    .foregroundColor(notification.isRead ? .white.opacity(0.4) : .red)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(notification.clientName) released you as their trainer")
                    .font(.system(size: 14, weight: notification.isRead ? .regular : .semibold))
                    .foregroundColor(notification.isRead ? .white.opacity(0.6) : .white)
                Text(notification.date, style: .relative).font(.caption).foregroundColor(.white.opacity(0.35))
                + Text(" ago").font(.caption).foregroundColor(.white.opacity(0.35))
            }
            Spacer()
            if !notification.isRead { Circle().fill(Color.red).frame(width: 8, height: 8) }
        }
        .padding(.vertical, 4)
    }
}
