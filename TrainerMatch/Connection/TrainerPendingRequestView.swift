//
//  TrainerPendingRequestsView.swift
//  TrainerMatch
//
//  Trainer sees pending client requests, accepts or declines.
//  After accepting: status → active, client notified, PAR-Q requested.
//

import SwiftUI

struct TrainerPendingRequestsView: View {
    let trainerId:   String
    let trainerName: String
    let authId:      String   // Supabase auth UUID for OneSignal targeting

    @ObservedObject private var connStore = SBConnectionStore.shared
    @ObservedObject private var parqStore = PARQStore.shared
    @Environment(\.dismiss) var dismiss

    @State private var isProcessing: Set<String> = []
    @State private var showSuccess  = false
    @State private var successName  = ""

    private var pending: [SBTrainerClientRow] {
        connStore.rows.filter { $0.trainerId.uuidString == trainerId && $0.status == "pending" }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.tmGold.opacity(0.15)).frame(width: 48, height: 48)
                            Image(systemName: "person.badge.clock.fill")
                                .font(.system(size: 20)).foregroundColor(.tmGold)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pending Requests")
                                .font(.system(size: 20, weight: .black)).foregroundColor(.white)
                            Text(pending.isEmpty
                                 ? "No pending requests"
                                 : "\(pending.count) client\(pending.count == 1 ? "" : "s") waiting for approval")
                                .font(.caption).foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        if pending.count > 0 {
                            Text("\(pending.count)")
                                .font(.system(size: 13, weight: .black)).foregroundColor(.black)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.tmGold))
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)
                    Divider().background(Color.white.opacity(0.08))
                }

                if pending.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            ForEach(pending) { row in
                                PendingClientCard(
                                    row:           row,
                                    isProcessing:  isProcessing.contains(row.id.uuidString),
                                    onAccept:      { Task { await accept(row) } },
                                    onDecline:     { Task { await decline(row) } }
                                )
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
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
        .onAppear { connStore.loadForTrainer(trainerId) }
        .alert("Client Accepted! 🎉", isPresented: $showSuccess) {
            Button("Great!") {}
        } message: {
            Text("\(successName) has been added to your client list. A PAR-Q form has been requested from them.")
        }
    }

    // MARK: - Accept

    private func accept(_ row: SBTrainerClientRow) async {
        let rowId = row.id.uuidString
        isProcessing.insert(rowId)
        defer { isProcessing.remove(rowId) }

        do {
            // 1. Update status to active
            try await connStore.acceptRequest(rowId, trainerName: trainerName)

            // 2. Reload trainer side
            connStore.loadForTrainer(trainerId)

            // 3. Get client name for notifications
            let clientName = row.clientName ?? "Your new client"
            let clientId   = row.clientId.uuidString

            // 4. Request PAR-Q from client
            parqStore.requestForm(
                trainerId:  trainerId,
                clientId:   clientId,
                clientName: clientName
            )

            // 5. Notify client they were accepted + PAR-Q prompt
            PushNotificationManager.shared.sendTrainerAcceptedNotification(
                toClientId:   clientId,
                trainerName:  trainerName
            )

            successName = clientName
            showSuccess = true
        } catch {
            print("❌ Accept failed: \(error)")
        }
    }

    // MARK: - Decline

    private func decline(_ row: SBTrainerClientRow) async {
        let rowId = row.id.uuidString
        isProcessing.insert(rowId)
        defer { isProcessing.remove(rowId) }
        do {
            try await connStore.declineRequest(rowId)
            connStore.loadForTrainer(trainerId)
        } catch {
            print("❌ Decline failed: \(error)")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.clock")
                .font(.system(size: 56)).foregroundColor(.tmGold.opacity(0.25)).padding(.top, 60)
            Text("All caught up!").font(.title3).fontWeight(.bold).foregroundColor(.white)
            Text("No pending client requests right now.\nNew requests will appear here when clients select you.")
                .font(.subheadline).foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Pending Client Card

struct PendingClientCard: View {
    let row:          SBTrainerClientRow
    let isProcessing: Bool
    let onAccept:     () -> Void
    let onDecline:    () -> Void

    @State private var clientImage: UIImage?

    private var clientName: String { row.clientName ?? "New Client" }
    private var initial:    String { String(clientName.prefix(1)).uppercased() }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Client info row
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.tmGold, .tmGoldDark],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 54, height: 54)
                    if let img = clientImage {
                        Image(uiImage: img)
                            .resizable().scaledToFill()
                            .frame(width: 54, height: 54)
                            .clipShape(Circle())
                    } else {
                        Text(initial)
                            .font(.title2).fontWeight(.black).foregroundColor(.black)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(clientName)
                        .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    Text("Requested to train with you")
                        .font(.caption).foregroundColor(.white.opacity(0.5))
                    if let date = row.joinedAt {
                        Text(date.formatted(.relative(presentation: .named)))
                            .font(.caption2).foregroundColor(.white.opacity(0.35))
                    }
                }
                Spacer()
                Text("NEW")
                    .font(.system(size: 9, weight: .black)).foregroundColor(.black)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(Color.tmGold))
            }

            // Action buttons
            if isProcessing {
                HStack {
                    Spacer()
                    ProgressView().tint(.tmGold)
                    Spacer()
                }
                .frame(height: 44)
            } else {
                HStack(spacing: 12) {
                    Button(action: onDecline) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                            Text("DECLINE")
                                .font(.system(size: 13, weight: .heavy)).tracking(0.5)
                        }
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)))
                    }

                    Button(action: onAccept) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("ACCEPT")
                                .font(.system(size: 13, weight: .heavy)).tracking(0.5)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 22)
                            .fill(Color.tmGold)
                            .shadow(color: Color.tmGold.opacity(0.4), radius: 8, y: 4))
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18)
            .fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .stroke(Color.tmGold.opacity(0.25), lineWidth: 1)))
        .onAppear { loadClientImage() }
        .onChange(of: row.clientImageUrl) { _, _ in loadClientImage() }
    }

    private func loadClientImage() {
        // First try from already-enriched URL
        if let urlStr = row.clientImageUrl, let url = URL(string: urlStr) {
            Task {
                if let data = try? await URLSession.shared.data(from: url).0,
                   let img = UIImage(data: data) {
                    await MainActor.run { clientImage = img }
                }
            }
            return
        }
        // Fallback: fetch directly from Supabase clients table
        Task {
            struct ClientPhoto: Decodable {
                let profileImageUrl: String?
                enum CodingKeys: String, CodingKey {
                    case profileImageUrl = "profile_image_url"
                }
            }
            if let result = try? await supabase
                .from("clients")
                .select("profile_image_url")
                .eq("id", value: row.clientId)
                .single().execute()
                .value as ClientPhoto,
               let urlStr = result.profileImageUrl,
               let url = URL(string: urlStr),
               let data = try? await URLSession.shared.data(from: url).0,
               let img = UIImage(data: data) {
                await MainActor.run { clientImage = img }
            }
        }
    }
}
