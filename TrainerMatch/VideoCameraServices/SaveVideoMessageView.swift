//
//  SaveVideoMessageView.swift
//  TrainerMatch
//

import SwiftUI
import AVKit

struct SaveVideoMessageView: View {
    @Binding var title:       String
    @Binding var message:     String
    @Binding var messageType: VideoMessage.MessageType
    let clientName: String
    @ObservedObject var viewModel: VideoMessageViewModel
    let onSend:   () -> Void
    let onCancel: () -> Void

    @State private var player: AVPlayer?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {

                        // Video preview
                        if let url = viewModel.temporaryVideoURL {
                            VideoPlayer(player: player)
                                .frame(height: 250)
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.tmGold, lineWidth: 2))
                                .onAppear { player = AVPlayer(url: url) }
                        }

                        VStack(spacing: 20) {

                            // Recipient
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2).foregroundColor(.tmGold)
                                Text("Sending to:").foregroundColor(.white.opacity(0.7))
                                Text(clientName).fontWeight(.bold).foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)

                            // Message type — Picker works cleanly with Identifiable enum
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Message Type")
                                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.tmGold)

                                Picker("Message Type", selection: $messageType) {
                                    ForEach(VideoMessage.MessageType.allCases) { type in
                                        HStack {
                                            Image(systemName: type.icon)
                                            Text(type.displayName)
                                        }
                                        .tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.tmGold)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.tmGold.opacity(0.3), lineWidth: 1))
                            }

                            // Title
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.tmGold)
                                TextField("e.g. Great progress this week!", text: $title)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.tmGold.opacity(0.3), lineWidth: 1))
                            }

                            // Message
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Message")
                                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.tmGold)
                                TextEditor(text: $message)
                                    .foregroundColor(.white)
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.tmGold.opacity(0.3), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal)

                        // Actions
                        VStack(spacing: 12) {
                            Button(action: { onSend(); dismiss() }) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("SEND VIDEO MESSAGE").fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity).padding()
                                .background(RoundedRectangle(cornerRadius: 25).fill(Color.tmGoldGradient()))
                                .foregroundColor(.black)
                                .shadow(color: .tmGold.opacity(0.5), radius: 10, x: 0, y: 5)
                            }
                            .disabled(title.isEmpty)

                            Button(action: { onCancel(); dismiss() }) {
                                Text("Cancel & Discard")
                                    .fontWeight(.semibold).foregroundColor(.white.opacity(0.7))
                                    .frame(maxWidth: .infinity).padding()
                                    .background(RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal).padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Review Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { onCancel(); dismiss() }.foregroundColor(.tmGold)
                }
            }
        }
    }
}
