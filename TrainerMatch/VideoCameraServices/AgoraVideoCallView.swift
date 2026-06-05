//
//  AgoraVideoCallView.swift
//  TrainerMatch
//
//  Live video calls between trainer and client using Agora RTC.
//  Agora App ID: a39e8f9686144cee997be986c433f21c
//

import SwiftUI
import AgoraRtcKit

// MARK: - Call Manager

class VideoCallManager: NSObject, ObservableObject {
    static let shared = VideoCallManager()

    private let appId = "a39e8f9686144cee997be986c433f21c"
    private var agoraKit: AgoraRtcEngineKit?

    @Published var isInCall        = false
    @Published var isLocalMuted    = false
    @Published var isRemoteMuted   = false
    @Published var isCameraOff     = false
    @Published var remoteUid:  UInt = 0
    @Published var callDuration:  Int = 0
    @Published var remoteJoined   = false
    @Published var callError:  String? = nil

    private var durationTimer: Timer?
    private var currentChannel = ""

    override private init() { super.init() }

    func setupAgora() {
        guard agoraKit == nil else { return }
        let config = AgoraRtcEngineConfig()
        config.appId = appId
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraKit?.enableVideo()
        agoraKit?.enableAudio()
        print("✅ Agora engine initialized")
    }

    func startCall(channel: String, token: String? = nil, uid: UInt = 0) {
        setupAgora()
        currentChannel = channel
        isInCall = true
        callDuration = 0
        remoteJoined = false
        callError = nil

        let option = AgoraRtcChannelMediaOptions()
        option.clientRoleType = .broadcaster
        option.channelProfile  = .communication

        let result = agoraKit?.joinChannel(
            byToken: token,
            channelId: channel,
            uid: uid,
            mediaOptions: option
        )

        if result == 0 {
            print("✅ Joined Agora channel: \(channel)")
            startDurationTimer()
        } else {
            callError = "Failed to join channel. Check your connection."
            isInCall = false
        }
    }

    func endCall() {
        agoraKit?.leaveChannel()
        stopDurationTimer()
        isInCall      = false
        remoteJoined  = false
        remoteUid     = 0
        callDuration  = 0
        isLocalMuted  = false
        isCameraOff   = false
        print("✅ Left Agora channel")
    }

    func toggleMute() {
        isLocalMuted.toggle()
        agoraKit?.muteLocalAudioStream(isLocalMuted)
    }

    func toggleCamera() {
        isCameraOff.toggle()
        agoraKit?.muteLocalVideoStream(isCameraOff)
    }

    func flipCamera() {
        agoraKit?.switchCamera()
    }

    func setupLocalVideo(canvas: AgoraRtcVideoCanvas) {
        agoraKit?.setupLocalVideo(canvas)
        agoraKit?.startPreview()
    }

    func setupRemoteVideo(canvas: AgoraRtcVideoCanvas) {
        agoraKit?.setupRemoteVideo(canvas)
    }

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.callDuration += 1
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }

    var formattedDuration: String {
        let m = callDuration / 60
        let s = callDuration % 60
        return String(format: "%02d:%02d", m, s)
    }

    // Generate a channel name from trainer + client IDs
    static func channelName(trainerId: String, clientId: String) -> String {
        let combined = "\(trainerId.prefix(8))_\(clientId.prefix(8))"
        return combined.filter { $0.isLetter || $0.isNumber || $0 == "_" }
    }
}

// MARK: - Agora Delegate

extension VideoCallManager: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        DispatchQueue.main.async {
            self.remoteUid    = uid
            self.remoteJoined = true
            print("✅ Remote user joined: \(uid)")
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        DispatchQueue.main.async {
            self.remoteJoined = false
            self.remoteUid    = 0
            print("⚠️ Remote user left: \(uid)")
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        DispatchQueue.main.async {
            self.callError = "Connection error (\(errorCode.rawValue)). Please try again."
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteAudioStateChangedOfUid uid: UInt,
                   state: AgoraAudioRemoteState, reason: AgoraAudioRemoteReason, elapsed: Int) {
        DispatchQueue.main.async {
            self.isRemoteMuted = (state == .stopped || state == .frozen)
        }
    }
}

// MARK: - Local Video View (UIViewRepresentable)

struct LocalVideoView: UIViewRepresentable {
    @ObservedObject var manager: VideoCallManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid     = 0
        canvas.view    = view
        canvas.renderMode = .hidden
        manager.setupLocalVideo(canvas: canvas)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Remote Video View (UIViewRepresentable)

struct RemoteVideoView: UIViewRepresentable {
    let uid: UInt
    @ObservedObject var manager: VideoCallManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor(white: 0.1, alpha: 1)
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid        = uid
        canvas.view       = view
        canvas.renderMode = .hidden
        manager.setupRemoteVideo(canvas: canvas)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Video Call View

struct AgoraVideoCallView: View {
    let channelName: String
    let isTrainer:   Bool
    let remotePersonName: String
    let token: String?

    @StateObject private var manager = VideoCallManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingEndConfirm = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Remote video (full screen)
            if manager.remoteJoined {
                RemoteVideoView(uid: manager.remoteUid, manager: manager)
                    .ignoresSafeArea()
            } else {
                // Waiting screen
                waitingView
            }

            // Local video (picture-in-picture)
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        if !manager.isCameraOff {
                            LocalVideoView(manager: manager)
                                .frame(width: 110, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.tmGold, lineWidth: 2))
                                .shadow(color: .black.opacity(0.5), radius: 8)
                        } else {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 110, height: 160)
                                .overlay(
                                    VStack(spacing: 6) {
                                        Image(systemName: "video.slash.fill")
                                            .font(.title2).foregroundColor(.white.opacity(0.5))
                                        Text("Camera Off").font(.caption2)
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                )
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1))
                        }
                    }
                    .padding(.top, 60).padding(.trailing, 16)
                }
                Spacer()
            }

            // Top bar
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(remotePersonName)
                            .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        HStack(spacing: 6) {
                            if manager.remoteJoined {
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                                Text(manager.formattedDuration)
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                            } else {
                                Circle().fill(Color.orange).frame(width: 8, height: 8)
                                Text("Waiting to connect...")
                                    .font(.caption).foregroundColor(.white.opacity(0.7))
                            }
                        }
                        if manager.isRemoteMuted {
                            HStack(spacing: 4) {
                                Image(systemName: "mic.slash.fill").font(.caption2).foregroundColor(.orange)
                                Text("Muted").font(.caption2).foregroundColor(.orange)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.top, 56).padding(.horizontal, 20)
                .padding(.bottom, 12)
                .background(LinearGradient(colors: [.black.opacity(0.7), .clear],
                                           startPoint: .top, endPoint: .bottom))
                Spacer()
            }

            // Bottom controls
            VStack {
                Spacer()
                if let error = manager.callError {
                    Text(error).font(.caption).foregroundColor(.orange)
                        .padding(.horizontal, 20).padding(.bottom, 8)
                }
                controlBar
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            manager.startCall(channel: channelName, token: token)
        }
        .onDisappear {
            manager.endCall()
        }
        .confirmationDialog(
            "End the call with \(remotePersonName)?",
            isPresented: $showingEndConfirm,
            titleVisibility: .visible
        ) {
            Button("End Call", role: .destructive) {
                manager.endCall()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .ignoresSafeArea()
    }

    private var waitingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.tmGold.opacity(0.3 - Double(i) * 0.08), lineWidth: 1)
                        .frame(width: CGFloat(120 + i * 40), height: CGFloat(120 + i * 40))
                }
                Circle().fill(Color.tmGold.opacity(0.15)).frame(width: 100, height: 100)
                Image(systemName: "video.fill").font(.system(size: 40)).foregroundColor(.tmGold)
            }
            VStack(spacing: 8) {
                Text("Calling \(remotePersonName)...")
                    .font(.title3).fontWeight(.bold).foregroundColor(.white)
                Text("Waiting for them to join")
                    .font(.subheadline).foregroundColor(.white.opacity(0.5))
            }
            Spacer()
        }
    }

    private var controlBar: some View {
        HStack(spacing: 24) {
            // Mute
            callButton(
                icon: manager.isLocalMuted ? "mic.slash.fill" : "mic.fill",
                label: manager.isLocalMuted ? "Unmute" : "Mute",
                color: manager.isLocalMuted ? .red : .white,
                bg: Color.white.opacity(0.15)
            ) { manager.toggleMute() }

            // Camera
            callButton(
                icon: manager.isCameraOff ? "video.slash.fill" : "video.fill",
                label: manager.isCameraOff ? "Camera On" : "Camera Off",
                color: manager.isCameraOff ? .red : .white,
                bg: Color.white.opacity(0.15)
            ) { manager.toggleCamera() }

            // End Call
            callButton(
                icon: "phone.down.fill",
                label: "End",
                color: .white,
                bg: Color.red,
                size: 60
            ) { showingEndConfirm = true }

            // Flip Camera
            callButton(
                icon: "camera.rotate.fill",
                label: "Flip",
                color: .white,
                bg: Color.white.opacity(0.15)
            ) { manager.flipCamera() }

            // Speaker (placeholder)
            callButton(
                icon: "speaker.wave.2.fill",
                label: "Speaker",
                color: .white,
                bg: Color.white.opacity(0.15)
            ) { }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            LinearGradient(colors: [.clear, .black.opacity(0.8)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private func callButton(icon: String, label: String, color: Color,
                             bg: Color, size: CGFloat = 52,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(bg).frame(width: size, height: size)
                    Image(systemName: icon).font(.system(size: size * 0.38)).foregroundColor(color)
                }
                Text(label).font(.system(size: 10, weight: .semibold)).foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Call Invite Sheet (shown before joining)

struct VideoCallInviteView: View {
    let channelName:      String
    let remotePersonName: String
    let isTrainer:        Bool
    let token:            String?
    let onJoin:           () -> Void
    let onDecline:        () -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()

                // Animated ring
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.tmGold.opacity(0.25 - Double(i) * 0.07), lineWidth: 1.5)
                            .frame(width: CGFloat(140 + i * 44), height: CGFloat(140 + i * 44))
                    }
                    Circle().fill(Color.tmGold.opacity(0.15)).frame(width: 120, height: 120)
                    Image(systemName: "video.fill").font(.system(size: 48)).foregroundColor(.tmGold)
                }

                VStack(spacing: 10) {
                    Text(isTrainer ? "Start Video Call" : "Incoming Video Call")
                        .font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Text(isTrainer
                         ? "Start a live video session with \(remotePersonName)"
                         : "\(remotePersonName) is calling you")
                        .font(.subheadline).foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                }

                HStack(spacing: 40) {
                    // Decline
                    Button(action: { onDecline(); dismiss() }) {
                        VStack(spacing: 8) {
                            Circle().fill(Color.red).frame(width: 70, height: 70)
                                .overlay(Image(systemName: "phone.down.fill")
                                    .font(.title2).foregroundColor(.white))
                            Text("Decline").font(.caption).fontWeight(.semibold).foregroundColor(.white)
                        }
                    }

                    // Accept / Join
                    Button(action: { onJoin(); dismiss() }) {
                        VStack(spacing: 8) {
                            Circle().fill(Color.green).frame(width: 70, height: 70)
                                .overlay(Image(systemName: "video.fill")
                                    .font(.title2).foregroundColor(.white))
                            Text(isTrainer ? "Start" : "Join").font(.caption).fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }

                Spacer()
            }
        }
    }
}
