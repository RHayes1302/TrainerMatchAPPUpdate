//
//  AppointmentRequestStore.swift
//  TrainerMatch
//
//  Client-to-trainer appointment requests
//

import SwiftUI

// MARK: - Shared UI helpers

func apptSectionHeader(_ title: String, icon: String) -> some View {
    HStack(spacing: 8) {
        Image(systemName: icon).font(.caption).foregroundColor(.tmGold)
        Text(title).font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
    }
}

// MARK: - Model

struct AppointmentRequest: Identifiable, Codable {
    let id: String
    let trainerId: String
    let clientId: String
    let clientName: String
    var title: String
    var sessionType: TrainerEvent.EventType
    var preferredDate: Date
    var endDate: Date
    var note: String?
    var status: RequestStatus
    var respondedAt: Date?
    var trainerNote: String?
    var trainerName: String?

    enum RequestStatus: String, Codable {
        case pending   = "Pending"
        case accepted  = "Accepted"
        case declined  = "Declined"
        case cancelled = "Cancelled"
    }

    init(trainerId: String, clientId: String, clientName: String,
         title: String, sessionType: TrainerEvent.EventType,
         preferredDate: Date, endDate: Date, note: String? = nil) {
        self.id            = UUID().uuidString
        self.trainerId     = trainerId
        self.clientId      = clientId
        self.clientName    = clientName
        self.title         = title
        self.sessionType   = sessionType
        self.preferredDate = preferredDate
        self.endDate       = endDate
        self.note          = note
        self.status        = .pending
    }

    var formattedDate: String {
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d yyyy"
        return f.string(from: preferredDate)
    }

    var formattedTime: String {
        let f = DateFormatter(); f.timeStyle = .short
        return "\(f.string(from: preferredDate)) – \(f.string(from: endDate))"
    }
}

// MARK: - Store

class AppointmentRequestStore: ObservableObject {
    static let shared = AppointmentRequestStore()
    @Published var requests: [AppointmentRequest] = []

    private var storeURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("appointmentRequests.json")
    }

    private init() { load() }

    // Client queries
    func requests(forClient clientId: String, trainerId: String) -> [AppointmentRequest] {
        requests.filter { $0.clientId == clientId && $0.trainerId == trainerId && $0.status != .cancelled }
            .sorted { $0.preferredDate < $1.preferredDate }
    }

    // Trainer queries
    func pendingRequests(forTrainer trainerId: String) -> [AppointmentRequest] {
        requests.filter { $0.trainerId == trainerId && $0.status == .pending }
            .sorted { $0.preferredDate < $1.preferredDate }
    }

    func allRequests(forTrainer trainerId: String) -> [AppointmentRequest] {
        requests.filter { $0.trainerId == trainerId && $0.status != .cancelled }
            .sorted { $0.preferredDate < $1.preferredDate }
    }

    // Actions
    func addRequest(_ req: AppointmentRequest) {
        requests.insert(req, at: 0); save()
        NotificationManager.shared.notifyAppointmentRequest(
            to: req.trainerId, from: req.clientId,
            clientName: req.clientName,
            sessionTitle: req.title, date: req.preferredDate
        )
    }

    func cancelRequest(_ req: AppointmentRequest) {
        update(req.id) { $0.status = .cancelled; $0.respondedAt = Date() }
    }

    func acceptRequest(_ req: AppointmentRequest, trainerNote: String? = nil) {
        update(req.id) {
            $0.status = .accepted
            $0.respondedAt = Date()
            $0.trainerNote = trainerNote
        }
        NotificationManager.shared.notifyAppointmentAccepted(
            to: req.clientId, from: req.trainerId,
            trainerName: req.trainerName ?? "Your trainer",
            sessionTitle: req.title, date: req.preferredDate
        )
        // Auto-create event on the trainer's calendar
        let event = TrainerEvent(
            trainerId: req.trainerId,
            title: req.title,
            eventType: req.sessionType,
            clientId: req.clientId,
            clientName: req.clientName,
            startDate: req.preferredDate,
            endDate: req.endDate,
            notes: req.note,
            color: .gold
        )
        TrainerScheduleStore.shared.addEvent(event)
    }

    func declineRequest(_ req: AppointmentRequest, trainerNote: String? = nil) {
        update(req.id) {
            $0.status = .declined
            $0.respondedAt = Date()
            $0.trainerNote = trainerNote
        }
        NotificationManager.shared.notifyAppointmentDeclined(
            to: req.clientId, from: req.trainerId,
            trainerName: req.trainerName ?? "Your trainer",
            sessionTitle: req.title
        )
    }

    private func update(_ id: String, mutation: (inout AppointmentRequest) -> Void) {
        if let i = requests.firstIndex(where: { $0.id == id }) {
            mutation(&requests[i]); save()
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(requests) else { return }
        try? data.write(to: storeURL)
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storeURL.path),
              let data = try? Data(contentsOf: storeURL),
              let saved = try? JSONDecoder().decode([AppointmentRequest].self, from: data)
        else { return }
        requests = saved
    }
}

// MARK: - Trainer: Incoming Requests View

struct TrainerIncomingRequestsView: View {
    let trainerId: String
    @ObservedObject private var requestStore = AppointmentRequestStore.shared
    @ObservedObject private var scheduleStore = TrainerScheduleStore.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedRequest: AppointmentRequest?
    @State private var showingRespond = false

    private var pending: [AppointmentRequest] {
        requestStore.pendingRequests(forTrainer: trainerId)
    }

    private var past: [AppointmentRequest] {
        requestStore.allRequests(forTrainer: trainerId).filter { $0.status != .pending }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    if pending.isEmpty && past.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray").font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.15)).padding(.top, 40)
                            Text("No requests yet")
                                .font(.title3).fontWeight(.bold).foregroundColor(.white)
                            Text("When clients request sessions they'll appear here.")
                                .font(.subheadline).foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        if !pending.isEmpty {
                            apptSectionHeader("PENDING — \(pending.count)", icon: "clock.badge.fill")
                                .padding(.top, 4)
                            ForEach(pending) { req in
                                TrainerRequestCard(request: req, onTap: {
                                    selectedRequest = req
                                    showingRespond = true
                                })
                            }
                        }
                        if !past.isEmpty {
                            apptSectionHeader("PAST REQUESTS", icon: "checkmark.circle")
                                .padding(.top, 8)
                            ForEach(past) { req in
                                TrainerRequestCard(request: req, onTap: nil)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Session Requests")
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
        }
        .sheet(isPresented: $showingRespond) {
            if let req = selectedRequest {
                NavigationView {
                    TrainerRespondRequestView(request: req)
                }
                .tint(.tmGold)
            }
        }
    }
}

struct TrainerRequestCard: View {
    let request: AppointmentRequest
    let onTap: (() -> Void)?

    var statusColor: Color {
        switch request.status {
        case .pending:   return .tmGold
        case .accepted:  return .green
        case .declined:  return Color(red: 0.9, green: 0.2, blue: 0.2)
        case .cancelled: return .gray
        }
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 3).fill(statusColor).frame(width: 4, height: 56)

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(request.title)
                            .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                        Spacer()
                        Text(request.status.rawValue)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(request.status == .pending ? .black : .white)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Capsule().fill(statusColor))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill").font(.caption2).foregroundColor(.tmGold)
                        Text(request.clientName).font(.caption).foregroundColor(.tmGold)
                    }
                    Text("\(request.formattedDate) · \(request.formattedTime)")
                        .font(.caption).foregroundColor(.white.opacity(0.45))
                    if let note = request.note {
                        Text(note).font(.caption2).foregroundColor(.white.opacity(0.35)).lineLimit(1)
                    }
                }

                if onTap != nil {
                    Image(systemName: "chevron.right").font(.caption)
                        .foregroundColor(.tmGold.opacity(0.6))
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(statusColor.opacity(0.25), lineWidth: 1)))
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

// MARK: - Trainer respond to request

struct TrainerRespondRequestView: View {
    let request: AppointmentRequest
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var requestStore = AppointmentRequestStore.shared
    @State private var trainerNote = ""
    @State private var showingConflict = false
    @State private var conflictNames = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {

                    // Request details card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("REQUEST DETAILS")
                            .font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)

                        detailRow("Client", value: request.clientName, icon: "person.fill")
                        detailRow("Session", value: request.title, icon: "figure.strengthtraining.traditional")
                        detailRow("Date", value: request.formattedDate, icon: "calendar")
                        detailRow("Time", value: request.formattedTime, icon: "clock.fill")
                        detailRow("Type", value: request.sessionType.rawValue, icon: "tag.fill")
                        if let note = request.note {
                            detailRow("Client Note", value: note, icon: "text.bubble.fill")
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1)))

                    // Optional note back
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTE TO CLIENT (OPTIONAL)")
                            .font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                        TextField("e.g. See you then! Bring water.", text: $trainerNote, axis: .vertical)
                            .foregroundColor(.white).lineLimit(3...5).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }

                    // Accept
                    Button(action: acceptRequest) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("ACCEPT & ADD TO CALENDAR")
                                .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 27).fill(Color.green))
                    }

                    // Decline
                    Button(action: declineRequest) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                            Text("DECLINE REQUEST")
                                .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 27)
                            .fill(Color.red.opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 27)
                                .stroke(Color.red.opacity(0.4), lineWidth: 1)))
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Respond to Request")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .alert("Schedule Conflict", isPresented: $showingConflict) {
            Button("Go Back", role: .cancel) {}
            Button("Accept Anyway") { requestStore.acceptRequest(request, trainerNote: trainerNote.isEmpty ? nil : trainerNote); dismiss() }
        } message: {
            Text("This overlaps with: \(conflictNames). Accept anyway?")
        }
    }

    private func acceptRequest() {
        let draft = TrainerEvent(
            trainerId: request.trainerId, title: request.title,
            eventType: request.sessionType, clientId: request.clientId,
            clientName: request.clientName, startDate: request.preferredDate,
            endDate: request.endDate
        )
        let conflicts = TrainerScheduleStore.shared.conflicts(for: draft)
        if conflicts.isEmpty {
            requestStore.acceptRequest(request, trainerNote: trainerNote.isEmpty ? nil : trainerNote)
            dismiss()
        } else {
            conflictNames = conflicts.map(\.title).joined(separator: ", ")
            showingConflict = true
        }
    }

    private func declineRequest() {
        requestStore.declineRequest(request, trainerNote: trainerNote.isEmpty ? nil : trainerNote)
        dismiss()
    }

    private func detailRow(_ label: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.caption).foregroundColor(.tmGold).frame(width: 16)
            Text(label).font(.caption).foregroundColor(.white.opacity(0.4)).frame(width: 70, alignment: .leading)
            Text(value).font(.caption).foregroundColor(.white).lineLimit(2)
        }
    }
}
