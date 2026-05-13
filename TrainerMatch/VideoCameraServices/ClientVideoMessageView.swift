//
//  ClientVideoMessageView.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/12/26.
//

//
//  ClientVideoMessagesView.swift
//  TrainerMatch
//
//  View showing all video messages sent to a client
//

import SwiftUI
import AVKit

struct ClientVideoMessagesView: View {
    @ObservedObject var viewModel: VideoMessageViewModel
    let clientId: String
    let clientName: String
    
    @State private var selectedMessage: VideoMessage?
    @State private var showingPlayer = false
    @State private var filterType: VideoMessage.MessageType?
    
    var filteredMessages: [VideoMessage] {
        let messages = viewModel.getMessages(for: clientId)
        if let type = filterType {
            return messages.filter { $0.messageType == type }
        }
        return messages
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Video Messages")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("for \(clientName)")
                                .font(.subheadline)
                                .foregroundColor(.tmGold)
                        }
                        Spacer()
                        
                        // Unviewed count badge
                        let unviewedCount = viewModel.getUnviewedCount(for: clientId)
                        if unviewedCount > 0 {
                            Text("\(unviewedCount)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.tmGold)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Filter buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterButton(
                                title: "All",
                                isSelected: filterType == nil,
                                action: { filterType = nil }
                            )
                            
                            ForEach([VideoMessage.MessageType.progressFeedback,
                                    .workoutInstructions,
                                    .motivational,
                                    .checkIn,
                                    .formCorrection], id: \.self) { type in
                                FilterButton(
                                    title: type.rawValue,
                                    isSelected: filterType == type,
                                    action: { filterType = type }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                }
                .background(Color.white.opacity(0.05))
                
                // Messages list
                if filteredMessages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No messages yet")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                        if filterType != nil {
                            Text("Try selecting a different filter")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredMessages) { message in
                                VideoMessageCard(message: message) {
                                    selectedMessage = message
                                    showingPlayer = true
                                    if !message.isViewed {
                                        viewModel.markAsViewed(message)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPlayer) {
            if let message = selectedMessage {
                VideoMessagePlayerView(
                    message: message,
                    onClose: { showingPlayer = false }
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.tmGold : Color.white.opacity(0.1))
                )
        }
    }
}

struct VideoMessageCard: View {
    let message: VideoMessage
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail placeholder with play button
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .aspectRatio(16/9, contentMode: .fit)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.tmGold)
                        
                        Text(message.formattedDuration)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(12)
                    }
                    
                    // Status badges
                    VStack {
                        HStack {
                            if message.isNew {
                                Text("NEW")
                                    .font(.caption2).fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.tmGold).cornerRadius(8)
                            }
                            if message.uploadStatus == .uploading {
                                HStack(spacing: 4) {
                                    ProgressView().tint(.white).scaleEffect(0.6)
                                    Text("Uploading")
                                        .font(.caption2).foregroundColor(.white)
                                }
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.black.opacity(0.6)).cornerRadius(8)
                            } else if message.uploadStatus == .failed {
                                Text("⚠️ Upload failed")
                                    .font(.caption2).foregroundColor(.orange)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.black.opacity(0.6)).cornerRadius(8)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(12)
                }
                
                // Message info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: iconForMessageType(message.messageType))
                            .foregroundColor(.tmGold)
                            .font(.caption)
                        Text(message.messageType.rawValue)
                            .font(.caption)
                            .foregroundColor(.tmGold)
                        Spacer()
                        Text(message.timeAgo)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Text(message.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(message.message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                .padding()
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(message.isNew ? Color.tmGold : Color.white.opacity(0.1), lineWidth: message.isNew ? 2 : 1)
            )
        }
    }
    
    private func iconForMessageType(_ type: VideoMessage.MessageType) -> String {
        switch type {
        case .progressFeedback:
            return "chart.line.uptrend.xyaxis"
        case .workoutInstructions:
            return "figure.strengthtraining.traditional"
        case .motivational:
            return "flame.fill"
        case .checkIn:
            return "checkmark.circle.fill"
        case .formCorrection:
            return "eye.fill"
        case .general:
            return "message.fill"
        }
    }
}

struct VideoMessagePlayerView: View {
    let message: VideoMessage
    let onClose: () -> Void

    // Initialise the player immediately so VideoPlayer has it on first render
    @StateObject private var playerHolder = VideoPlayerHolder()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {

                // Close button row
                HStack {
                    Button(action: {
                        playerHolder.player.pause()
                        onClose()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3).fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    Spacer()
                    // Upload status indicator
                    if message.uploadStatus == .uploading {
                        HStack(spacing: 6) {
                            ProgressView().tint(.tmGold).scaleEffect(0.7)
                            Text("Uploading...").font(.caption).foregroundColor(.tmGold)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                    } else if message.uploadStatus == .failed {
                        Text("⚠️ Upload failed")
                            .font(.caption).foregroundColor(.orange)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Capsule().fill(Color.black.opacity(0.6)))
                    }
                    // Duration badge
                    Text(message.formattedDuration)
                        .font(.caption).fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                }
                .padding(16)

                // ── Video Player ──
                VideoPlayer(player: playerHolder.player)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(9/16, contentMode: .fit)
                    .background(Color.black)
                    .onAppear {
                        if message.playbackURL != nil {
                            playerHolder.player.play()
                        }
                    }

                // No playback URL warning
                if message.playbackURL == nil {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text(message.uploadStatus == .uploading
                             ? "Video is uploading — available soon."
                             : "Video not yet available on this device.")
                            .font(.caption).foregroundColor(.white.opacity(0.6))
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.1)))
                    .padding(.horizontal)
                }

                // Message details
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: iconForMessageType(message.messageType))
                                .foregroundColor(.tmGold).font(.caption)
                            Text(message.messageType.rawValue)
                                .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                            Spacer()
                            Text(message.formattedDate)
                                .font(.caption2).foregroundColor(.white.opacity(0.5))
                        }
                        Text(message.title)
                            .font(.title3).fontWeight(.bold).foregroundColor(.white)
                        if !message.message.isEmpty {
                            Text(message.message)
                                .font(.subheadline).foregroundColor(.white.opacity(0.75))
                        }
                    }
                    .padding(16)
                }
                .background(Color.white.opacity(0.04))
            }
        }
        .onAppear {
            if let url = message.playbackURL {
                playerHolder.player.replaceCurrentItem(with: AVPlayerItem(url: url))
            }
        }
        .onDisappear {
            playerHolder.player.pause()
        }
    }

    private func iconForMessageType(_ type: VideoMessage.MessageType) -> String {
        switch type {
        case .progressFeedback:     return "chart.line.uptrend.xyaxis"
        case .workoutInstructions:  return "figure.strengthtraining.traditional"
        case .motivational:         return "flame.fill"
        case .checkIn:              return "checkmark.circle.fill"
        case .formCorrection:       return "eye.fill"
        case .general:              return "message.fill"
        }
    }
}

/// Holds an AVPlayer that is created immediately (non-optional),
/// so VideoPlayer always has a valid player on first render.
final class VideoPlayerHolder: ObservableObject {
    let player = AVPlayer()
}

#Preview {
    NavigationView {
        ClientVideoMessagesView(
            viewModel: VideoMessageViewModel.shared,
            clientId: "client1",
            clientName: "John Doe"
        )
    }
}
