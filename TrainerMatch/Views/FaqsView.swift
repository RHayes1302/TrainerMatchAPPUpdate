//
//  FaqsView.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/10/26.
//

import SwiftUI

struct FAQsView: View {
    @State private var expandedIndex: Int? = nil
    
    let faqs: [(question: String, answer: String)] = [
        (
            "How do I find a trainer on TrainerMatch?",
            "Find trainers on TrainerMatch by entering the location, selecting specialties like personal training, yoga or weightlifting, and choosing online or in-person training."
        ),
        (
            "What happens after I contact a trainer?",
            "After you contact a trainer through TrainerMatch, they will respond directly to discuss your fitness goals, schedule, and pricing options."
        ),
        (
            "Who handles payment for training services?",
            "Payment is handled directly between you and your trainer. TrainerMatch provides the platform to connect, but all financial arrangements are made independently."
        ),
        (
            "Who is responsible for trainer qualifications and services?",
            "Trainers are responsible for their own qualifications, certifications, and services. We encourage you to verify credentials and ask questions before committing."
        ),
        (
            "Is my personal data secure?",
            "Yes, we take data security seriously and use industry-standard encryption to protect your personal information."
        ),
        (
            "How do I cancel or change my training sessions?",
            "Session cancellations and changes are handled directly with your trainer. Please communicate with them about their cancellation policy."
        ),
        (
            "How do I get support or assistance?",
            "For support, you can reach out through our Contact page or email us. We're here to help with any questions about using TrainerMatch."
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
                    
                    // FREQUENTLY ASKED QUESTIONS Header
                    Text("FREQUENTLY ASKED QUESTIONS")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.tmGold)
                        .padding(.bottom, 24)
                    
                    // FAQ Items
                    VStack(spacing: 0) {
                        ForEach(faqs.indices, id: \.self) { index in
                            FAQItem(
                                question: faqs[index].question,
                                answer: faqs[index].answer,
                                isExpanded: expandedIndex == index,
                                onTap: {
                                    withAnimation {
                                        expandedIndex = expandedIndex == index ? nil : index
                                    }
                                }
                            )
                            
                            if index < faqs.count - 1 {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
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

struct FAQItem: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text(question)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.tmGold)
                        .font(.caption)
                }
                .padding(20)
            }
            
            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    NavigationView {
        FAQsView()
    }
}
