//
//  AboutUsView.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/10/26.
//

import SwiftUI

struct AboutUsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Black background
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // TrainerMatch Logo
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
                    
                    // THE MISSION Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("THE MISSION")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.tmGold)
                        
                        Text("Local Trainers, Real Results")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        Text("Welcome to Nearby Trainers, the premier platform for finding fitness trainers in your area. Our mission is to revolutionize the fitness industry by connecting individuals with top-notch trainers.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(6)
                            .padding(.horizontal, 20)
                        
                        Text("Founded on a passion for fitness, Nearby Trainers addresses the long-standing challenge of finding qualified trainers and accessible fitness options. With Nearby Trainers, users can effortlessly discover trainers tailored to their location, fitness goals and preferences.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(6)
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 32)
                    
                    // OUR VISION Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("OUR VISION")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.tmGold)
                        
                        Text("Our vision extends beyond a local directory. We aim to become the largest worldwide directory for fitness trainers, bridging gaps between fitness seekers and providers. By streamlining the search process, we empower individuals to prioritize wellness and healthy living.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(6)
                            .padding(.horizontal, 20)
                        
                        Text("By centralizing trainer information, we foster accessibility, diversity and innovation. Join us in transforming the fitness landscape, making wellness more approachable and enjoyable for everyone!")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineSpacing(6)
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationView {
        AboutUsView()
    }
}
