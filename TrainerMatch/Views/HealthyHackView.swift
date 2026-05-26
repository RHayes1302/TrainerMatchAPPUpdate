//
//  HealthyHackView.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/10/26.
//

import SwiftUI

struct HealthyHacksView: View {
    let articles = [
        Article(
            title: "Keto Diets: The Ultimate Muscle Building Hack For Fitness Success",
            excerpt: "Adopting a keto diet can be a highly effective way to build muscle and shred unwanted body fat by leveraging the power of ketosis and strategic nutrition.",
            imageName: "fork.knife"
        ),
        Article(
            title: "Rise And Grind: Morning Cardio Routines Forge Rock-Solid Abs",
            excerpt: "Engaging in cardio routines in the morning can be a game-changer for those seeking to build core strength and achieve visible abs through consistent training.",
            imageName: "figure.run"
        )
    ]
    
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
                    
                    // HEALTHY HACKS Header
                    Text("HEALTHY HACKS")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.tmGold)
                        .padding(.bottom, 24)
                    
                    // Articles
                    VStack(spacing: 20) {
                        ForEach(articles) { article in
                            ArticleCard(article: article)
                        }
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

struct Article: Identifiable {
    let id = UUID()
    let title: String
    let excerpt: String
    let imageName: String
}

struct ArticleCard: View {
    let article: Article
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    .frame(height: 180)
                
                Image(systemName: article.imageName)
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            // Title and excerpt
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(.tmGold)
                    .lineLimit(2)
                
                Text(article.excerpt)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
                    .lineLimit(3)
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
        HealthyHacksView()
    }
}
