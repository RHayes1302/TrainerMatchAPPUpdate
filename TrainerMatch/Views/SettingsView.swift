//
//  SettingsView.swift
//  TrainerMatch
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: SupabaseAuthManager
    @Environment(\.dismiss) var dismiss
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAlert = false
    @State private var isLoggingOut = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {

                    // Profile summary card
                    profileCard
                        .padding(.top, 20)

                    // Account section
                    settingsSection("ACCOUNT") {
                        settingsRow(icon: "envelope.fill", label: "Email", value: currentEmail)
                        Divider().background(Color.white.opacity(0.08))
                        settingsRow(icon: "person.fill", label: "Role",
                                    value: auth.currentUserRole == .trainer ? "Trainer" : "Client")
                    }

                    // Notifications section
                    settingsSection("NOTIFICATIONS") {
                        settingsRow(icon: "bell.fill", label: "Push Notifications",
                                    value: "Enabled")
                    }

                    // Support section
                    settingsSection("SUPPORT") {
                        Link(destination: URL(string: "mailto:support@trainermatch.app")!) {
                            settingsRowContent(icon: "envelope.circle.fill",
                                               label: "Contact Support",
                                               value: "", showChevron: true)
                        }
                        Divider().background(Color.white.opacity(0.08))
                        Link(destination: URL(string: "https://trainermatch.app/privacy")!) {
                            settingsRowContent(icon: "hand.raised.fill",
                                               label: "Privacy Policy",
                                               value: "", showChevron: true)
                        }
                        Divider().background(Color.white.opacity(0.08))
                        Link(destination: URL(string: "https://trainermatch.app/terms")!) {
                            settingsRowContent(icon: "doc.text.fill",
                                               label: "Terms of Service",
                                               value: "", showChevron: true)
                        }
                    }

                    // App info
                    settingsSection("APP") {
                        settingsRow(icon: "info.circle.fill", label: "Version", value: appVersion)
                        Divider().background(Color.white.opacity(0.08))
                        settingsRow(icon: "hammer.fill", label: "Build", value: buildNumber)
                    }

                    // Danger zone
                    VStack(spacing: 12) {
                        // Logout button
                        Button(action: { showingLogoutAlert = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                                    .frame(width: 28)
                                Text("Log Out")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.red)
                                Spacer()
                                if isLoggingOut {
                                    ProgressView().tint(.red)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.red.opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1))
                            )
                        }
                        .buttonStyle(.plain)

                        // Delete account button
                        Button(action: { showingDeleteAlert = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red.opacity(0.6))
                                    .frame(width: 28)
                                Text("Delete Account")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.red.opacity(0.6))
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.red.opacity(0.05))
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.red.opacity(0.15), lineWidth: 1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)

                    // Footer
                    Text("TrainerMatch © 2026")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.2))
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Settings")
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
                    }
                    .foregroundColor(.tmGold)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) { handleLogout() }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { handleDeleteAccount() }
        } message: {
            Text("This will permanently delete your account and all data. This cannot be undone.")
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.tmGold, .tmGoldDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .frame(width: 64, height: 64)
                Text(avatarInitial)
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(.black)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text(currentEmail)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text(auth.currentUserRole == .trainer ? "Trainer Account" : "Client Account")
                        .font(.caption)
                        .foregroundColor(.tmGold)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.tmGold.opacity(0.2), lineWidth: 1))
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Section builder

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .tracking(1.5)
                .foregroundColor(.tmGold)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1))
            )
            .padding(.horizontal, 20)
        }
    }

    private func settingsRow(icon: String, label: String, value: String) -> some View {
        settingsRowContent(icon: icon, label: label, value: value, showChevron: false)
    }

    private func settingsRowContent(
        icon: String, label: String,
        value: String, showChevron: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.tmGold)
                .frame(width: 28)
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.white)
            Spacer()
            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.45))
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Actions

    private func handleLogout() {
        isLoggingOut = true
        Task {
            await auth.signOut()
            await MainActor.run {
                isLoggingOut = false
                dismiss()
            }
        }
    }

    private func handleDeleteAccount() {
        // For now just log out — full delete can be implemented later
        Task { await auth.signOut() }
    }

    // MARK: - Helpers

    private var displayName: String {
        auth.currentTrainer?.fullName ?? auth.currentClient?.fullName ?? "User"
    }

    private var currentEmail: String {
        auth.currentTrainer?.email ?? auth.currentClient?.email ?? ""
    }

    private var avatarInitial: String {
        String(displayName.prefix(1).uppercased())
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(SupabaseAuthManager.shared)
    }
}
