//
//  SuccesStoriesView.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/10/26.
//

import SwiftUI

struct SuccessStoriesView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Logo
                    VStack(spacing: 20) {
                        TrainerMatchLogo(size: .large)
                            .shadow(color: .tmGold.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        Text("Nearby Trainers")
                            .font(.system(size: 32, weight: .bold))
                            .italic()
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                    
                    // SUCCESS STORIES Header
                    Text("SUCCESS STORIES")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.tmGold)
                        .padding(.bottom, 24)
                    
                    // Stories
                    VStack(spacing: 24) {
                        SuccessStoryCard(
                            name: "Mario Kutz",
                            role: "Trainer",
                            story: "Mario Kutz' journey exemplifies determination and passion. Working full-time in the fast food industry while pursuing his dream of becoming a certified personal trainer demonstrates his commitment to helping others achieve their fitness goals.",
                            imageName: "figure.strengthtraining.traditional"
                        )
                        
                        SuccessStoryCard(
                            name: "Nick Thomas",
                            role: "Client",
                            story: "Nick Thomas's transformation is a testament to determination and expert guidance. Weighing 200+ pounds, Nick committed to a structured training program and achieved remarkable results, losing significant weight and gaining confidence.",
                            imageName: "figure.walk"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct SuccessStoryCard: View {
    let name: String
    let role: String
    let story: String
    let imageName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.tmGold.opacity(0.3), Color.tmGoldDark.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                
                Image(systemName: imageName)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            // Name and Role
            VStack(alignment: .leading, spacing: 4) {
                Text("\(name) – \(role)")
                    .font(.headline)
                    .foregroundColor(.tmGold)
                
                Text(story)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    NavigationView {
        SuccessStoriesView()
    }
}
