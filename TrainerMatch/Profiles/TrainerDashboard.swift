//
//  TrainedDashBoardView.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/10/26.
//

import SwiftUI

struct TrainerDashboardView: View {
    
    @StateObject private var trainerVM = TrainerViewModel()
    @State private var searchText = ""
    @State private var showingAddClient = false
    @State private var selectedSortOption: ClientSortOption = .recentlyAdded
    
    var filteredClients: [Client] {
        let searched = trainerVM.searchClients(query: searchText)
        return searched.sorted { client1, client2 in
            switch selectedSortOption {
            case .nameAscending:
                return client1.name < client2.name
            case .nameDescending:
                return client1.name > client2.name
            case .recentlyAdded:
                return client1.dateJoined > client2.dateJoined
            case .mostActive:
                return client1.dailySteps > client2.dailySteps
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // TrainerMatch Branding Header
                TrainerMatchHeaderView()
                    .padding(.horizontal)
                    .padding(.top)
                
                // Header Stats
                TrainerStatsHeaderView(clientCount: trainerVM.clients.count)
                    .padding()
                
                // Search and Sort
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search clients...", text: $searchText)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    HStack {
                        Text("Sort by:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Picker("Sort", selection: $selectedSortOption) {
                            ForEach(ClientSortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                // Client List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredClients) { client in
                            NavigationLink(destination:
                                ClientFolderView(
                                    trainerViewModel: trainerVM,
                                    client: client
                                )
                            ) {
                                ClientCardView(client: client, stats: trainerVM.getClientStats(for: client))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Clients")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: TrainerProfileMySpaceView(trainer: TrainerProfile.sampleProfile)) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.tmGold)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddClient = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.tmGold)
                    }
                }
            }
            .sheet(isPresented: $showingAddClient) {
                        AddClientView(trainerVM: trainerVM)
                    }
                    .onAppear {
                        if let id = AuthManager.shared.currentTrainerProfile?.id {
                            SBConnectionStore.shared.loadForTrainer(id)
                        }
                    }
                }
            }
}

// MARK: - Trainer Stats Header
struct TrainerStatsHeaderView: View {
    let clientCount: Int
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Clients")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("\(clientCount)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.tmGold)
            }
            
            Spacer()
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 40))
                .foregroundColor(.tmGold.opacity(0.3))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

// MARK: - Client Card View
struct ClientCardView: View {
    let client: Client
    let stats: ClientStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.tmGold, .tmGoldDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(client.name.prefix(1))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(client.email)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            
            Divider()
            
            HStack(spacing: 16) {
                StatBadge(icon: "figure.walk",        value: "\(client.dailySteps)", label: "steps",  color: .green)
                StatBadge(icon: "flame.fill",          value: "\(stats.activeWorkouts)", label: "active", color: .orange)
                StatBadge(icon: "checkmark.circle.fill", value: "\(Int(stats.completionRate))%", label: "done", color: .blue)
            }
            
            HStack {
                Circle().fill(activityColor).frame(width: 8, height: 8)
                Text(client.activityStatus).font(.caption).foregroundColor(.gray)
                Spacer()
                if let lastSync = client.lastSyncDate {
                    Text("Updated \(timeAgo(from: lastSync))").font(.caption2).foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var activityColor: Color {
        switch client.activityStatus {
        case "Very Active":       return .green
        case "Active":            return .blue
        case "Moderately Active": return .yellow
        case "Lightly Active":    return .orange
        default:                  return .red
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        if hours < 1  { return "just now" }
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption2)
                Text(value).font(.caption).fontWeight(.semibold)
            }
            .foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    TrainerDashboardView()
}
