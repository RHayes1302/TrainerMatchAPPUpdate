//
//  MainAppView.swift
//  TrainerMatch
//

import SwiftUI

// Note: This view is kept for reference but the app entry point is AppEntryView.
// Health tracker is now accessed via HealthTrackerContentView(clientId:trainerId:clientName:)
// from ClientProfileMySpaceView.

struct MainAppView: View {
    @State private var selectedRole: UserRole = .client

    var body: some View {
        TabView(selection: $selectedRole) {
            // Trainer View - Client Management
            TrainerDashboardView()
                .tabItem {
                    Label("My Clients", systemImage: "person.3.fill")
                }
                .tag(UserRole.trainer)
        }
    }
}

#Preview {
    MainAppView()
}
