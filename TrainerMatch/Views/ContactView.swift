//
//  ContactView.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/10/26.
//

import SwiftUI

struct ContactView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var mobile = ""
    @State private var message = ""
    @State private var agreedToGDPR = false
    @State private var showingAlert = false
    
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
                    
                    // CONTACT US Header
                    Text("CONTACT US")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.tmGold)
                        .padding(.bottom, 24)
                    
                    // Description
                    Text("Do you have any questions, suggestions, or inquiries? Feel free to reach out anytime! Our dedicated team will respond as soon as possible.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Name fields
                        HStack(spacing: 12) {
                            ContactTextField(placeholder: "First Name", text: $firstName)
                            ContactTextField(placeholder: "Last Name", text: $lastName)
                        }
                        
                        // Contact fields
                        HStack(spacing: 12) {
                            ContactTextField(placeholder: "Email Address", text: $email)
                            ContactTextField(placeholder: "Mobile", text: $mobile)
                        }
                        
                        // Message
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextEditor(text: $message)
                                .frame(height: 120)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .foregroundColor(.white)
                        }
                        
                        // GDPR Agreement
                        HStack(alignment: .top, spacing: 8) {
                            Button(action: {
                                agreedToGDPR.toggle()
                            }) {
                                Image(systemName: agreedToGDPR ? "checkmark.square.fill" : "square")
                                    .foregroundColor(agreedToGDPR ? .tmGold : .white.opacity(0.5))
                            }
                            
                            Text("I consent to having this platform store my submitted information.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Submit Button
                        Button(action: {
                            submitForm()
                        }) {
                            Text("SUBMIT")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isFormValid ? Color.tmGold : Color.gray.opacity(0.5))
                                )
                        }
                        .disabled(!isFormValid)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Thank You!", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {
                clearForm()
            }
        } message: {
            Text("Your message has been sent. We'll get back to you soon!")
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !message.isEmpty && agreedToGDPR
    }
    
    private func submitForm() {
        showingAlert = true
    }
    
    private func clearForm() {
        firstName = ""
        lastName = ""
        email = ""
        mobile = ""
        message = ""
        agreedToGDPR = false
    }
}

struct ContactTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .foregroundColor(.white)
    }
}

#Preview {
    NavigationView {
        ContactView()
    }
}
