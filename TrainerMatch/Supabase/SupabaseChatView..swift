//
//  SupabaseChatView.swift
//  TrainerMatch
//

import SwiftUI

struct SupabaseChatView: View {
    let trainerId:       UUID
    let clientId:        UUID
    let currentUserId:   UUID
    let currentUserName: String
    let otherPersonName: String

    // ✅ Own instance — not shared singleton
    @StateObject private var store = SBMessageStore()
    @State private var messageText  = ""
    @State private var sendError:   String? = nil
    @State private var isLoading    = true
    @FocusState private var inputFocused: Bool

    private var currentRole: String {
        currentUserId == trainerId ? "trainer" : "client"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                messagesView
                if let err = sendError {
                    Text("⚠️ \(err)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                }
                Divider().background(Color.white.opacity(0.1))
                inputBar
            }

            // ✅ Loading overlay — disappears as soon as messages load
            if isLoading {
                VStack(spacing: 14) {
                    ProgressView().tint(.tmGold).scaleEffect(1.2)
                    Text("Loading messages...")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
        }
        .navigationTitle(otherPersonName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            // ✅ Fetch messages first, then start realtime in background
            // UI is never blocked — loading spinner shows while fetching
            do {
                try await store.fetchMessages(trainerId: trainerId, clientId: clientId)
                print("✅ fetchMessages succeeded — \(store.messages.count) messages")
            } catch {
                print("❌ fetchMessages FAILED: \(error)")
                sendError = "Load failed: \(error.localizedDescription)"
            }
            isLoading = false
        }
        .onDisappear {
            Task { await store.unsubscribe() }
        }
    }

    // MARK: - Messages

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if store.messages.isEmpty && !isLoading {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.tmGold.opacity(0.3))
                                .padding(.top, 60)
                            Text("Start the conversation!")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.5))
                            Text("Say hello to \(otherPersonName)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.35))
                        }
                    } else {
                        ForEach(store.messages) { msg in
                            SupabaseMessageBubble(
                                message: msg,
                                isFromMe: msg.senderId == currentUserId
                            )
                            .id(msg.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .onChange(of: store.messages.count) { _, _ in
                if let last = store.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onAppear {
                if let last = store.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Message \(otherPersonName)...",
                      text: $messageText, axis: .vertical)
                .lineLimit(1...4)
                .foregroundColor(.white)
                .accentColor(.tmGold)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.tmGold.opacity(0.3), lineWidth: 1)))
                .focused($inputFocused)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? .white.opacity(0.2) : .tmGold
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.black)
    }

    // MARK: - Send

    private func sendMessage() {
        print("🔴 sendMessage CALLED")
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messageText = ""
        sendError = nil

        let message = MessageRow(
            id:         UUID(),
            trainerId:  trainerId,
            clientId:   clientId,
            senderId:   currentUserId,
            senderRole: currentRole,
            content:    text,
            mediaUrl:   nil,
            mediaType:  nil,
            isRead:     false,
            sentAt:     Date()
        )

        print("📤 Sending message: \(text)")

        Task {
            do {
                try await store.send(message)
                print("✅ Message sent OK")
            } catch {
                print("❌ Send FAILED: \(error)")
                await MainActor.run {
                    sendError = error.localizedDescription
                    messageText = text
                }
            }
        }
    }
}

// MARK: - Message Bubble

struct SupabaseMessageBubble: View {
    let message:  MessageRow
    let isFromMe: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromMe { Spacer(minLength: 50) }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isFromMe ? .black : .white)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isFromMe ? Color.tmGold : Color.white.opacity(0.1))
                    )
                Text((message.sentAt ?? Date()).formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
            }

            if !isFromMe { Spacer(minLength: 50) }
        }
    }
}
