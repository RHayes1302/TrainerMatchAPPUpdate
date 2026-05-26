//
//  TrainerMatchHeaderView.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/10/26.
//

import SwiftUI

struct TrainerMatchHeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            // TrainerMatch Logo - Consistent with rest of app
            HStack(spacing: 12) {
                TrainerMatchLogo(size: .small)
                    .shadow(color: .tmGold.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nearby Trainers")
                        .font(.title2)
                        .fontWeight(.bold)
                        .italic()
                        .foregroundColor(.white)
                    
                    Text("Local Trainers, Real Results")
                        .font(.caption)
                        .foregroundColor(.tmGold)
                }
                
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.black, Color.black.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
    }
}

#Preview {
    TrainerMatchHeaderView()
        .padding()
        .background(Color.gray.opacity(0.2))
}
