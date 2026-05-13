//
//  ChatStore.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/27/26.
//

//
//  ChatView.swift
//  TrainerMatch
//
//  Real-time style messaging between a connected trainer and client.
//

import SwiftUI

struct ChatView: View {
    let connection: TrainerClientConnection
    let currentUserId: String
    let currentUserName: String

    @ObservedObject private var store = TrainerConnectionStore.shared
    @State private var messageText = ""
    @FocusState private var inputFocused: Bool

    private var thread: [ChatMessage] {
        store.messages(forConnection: connection.id)
    }

    private var otherPersonName: String {
        currentUserId == connection.trainerId ? connection.clientName : connection.trainerName
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if thread.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.tmGold.opacity(0.3))
                                        .padding(.top, 60)
                                    Text("Start the conversation!")
                                        .font(.headline).foregroundColor(.white.opacity(0.5))
                                    Text("Say hello to \(otherPersonName)")
                                        .font(.subheadline).foregroundColor(.white.opacity(0.35))
                                }
                            } else {
                                ForEach(thread) { msg in
                                    MessageBubble(
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
                    .onChange(of: thread.count) { _, _ in
                        if let last = thread.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    .onAppear {
                        store.markRead(connectionId: connection.id, currentUserId: currentUserId)
                        if let last = thread.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                Divider().background(Color.white.opacity(0.1))

                // Input bar
                HStack(spacing: 12) {
                    TextField("Message \(otherPersonName)...", text: $messageText, axis: .vertical)
                        .lineLimit(1...4)
                        .foregroundColor(.white)
                        .accentColor(.tmGold)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.07))
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.tmGold.opacity(0.3), lineWidth: 1)))
                        .focused($inputFocused)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                            ? .white.opacity(0.2) : .tmGold)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color.black)
            }
        }
        .navigationTitle(otherPersonName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        store.sendMessage(
            connectionId: connection.id,
            senderId: currentUserId,
            senderName: currentUserName,
            text: text
        )
        messageText = ""
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let isFromMe: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromMe { Spacer(minLength: 50) }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .foregroundColor(isFromMe ? .black : .white)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isFromMe ? Color.tmGold : Color.white.opacity(0.1))
                    )

                Text(message.sentAt.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
            }

            if !isFromMe { Spacer(minLength: 50) }
        }
    }
}
