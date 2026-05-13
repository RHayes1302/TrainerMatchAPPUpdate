//
//  GymAdvertiserSignupView.swift
//  TrainerMatch
//
//  Gym/Studio advertiser signup — create profile, choose plan, subscribe.
//

import SwiftUI
import PhotosUI

struct GymAdvertiserSignupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var manager = GymAdManager.shared

    // Form state
    @State private var businessName  = ""
    @State private var tagline       = ""
    @State private var category: GymCategory = .gym
    @State private var selectedPlan: GymAd.AdPlan = .basic
    @State private var phone         = ""
    @State private var websiteURL    = ""
    @State private var streetAddress = ""
    @State private var city          = ""
    @State private var state         = ""
    @State private var zipCode       = ""
    @State private var email         = ""
    @State private var pin           = ""
    @State private var showPin       = false
    @State private var selectedAmenities: [String] = []
    @State private var selectedLogoItem: PhotosPickerItem?
    @State private var selectedLogoData: Data?
    @State private var isSubmitting  = false
    @State private var showSuccess   = false
    @State private var showError     = false
    @State private var errorMsg      = ""

    private var canSave: Bool {
        !businessName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !tagline.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        pin.count == 4
    }

    private var logoAllowed: Bool { selectedPlan != .basic }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // Header
                        VStack(spacing: 6) {
                            Image(systemName: "building.2.crop.circle.fill")
                                .font(.system(size: 52)).foregroundColor(.tmGold)
                            Text("List Your Gym or Studio")
                                .font(.system(size: 22, weight: .black)).foregroundColor(.white)
                            Text("Reach trainers and clients already using TrainerMatch in your area.")
                                .font(.caption).foregroundColor(.white.opacity(0.45))
                                .multilineTextAlignment(.center).padding(.horizontal)
                        }
                        .padding(.top, 10)

                        // Plan selector
                        planSection

                        // Logo upload
                        logoSection

                        // Business info
                        businessInfoSection

                        // Category
                        categorySection

                        // Amenities
                        amenitiesSection

                        // Location
                        locationSection

                        // Contact
                        contactSection

                        // What happens next
                        nextStepsCard
                    }
                    .padding(20)
                }

                // Submit button
                Button(action: { Task { await submit() } }) {
                    HStack(spacing: 8) {
                        if isSubmitting { ProgressView().tint(.black) }
                        else { Image(systemName: "paperplane.fill") }
                        Text(isSubmitting ? "SUBMITTING..." : "SUBMIT FOR REVIEW")
                            .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                    }
                    .foregroundColor(canSave && !isSubmitting ? .black : .white.opacity(0.3))
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 27)
                        .fill(canSave && !isSubmitting ? Color.tmGold : Color.white.opacity(0.08)))
                }
                .disabled(!canSave || isSubmitting)
                .padding(.horizontal, 20).padding(.vertical, 14)
            }
        }
        .navigationTitle("Advertise on TrainerMatch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .alert("Submitted!", isPresented: $showSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your listing has been submitted for review. We'll contact you at \(email) within 24 hours to complete your payment setup.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMsg)
        }
        .onChange(of: selectedLogoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img  = UIImage(data: data) {
                    var q: CGFloat = 0.8
                    var compressed = img.jpegData(compressionQuality: q) ?? data
                    while compressed.count > 400_000 && q > 0.1 {
                        q -= 0.1
                        compressed = img.jpegData(compressionQuality: q) ?? compressed
                    }
                    await MainActor.run { selectedLogoData = compressed }
                }
            }
        }
    }

    // MARK: Sections

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            formLabel("CHOOSE YOUR PLAN")
            VStack(spacing: 8) {
                planCard(.basic,    desc: "Name, tagline, category, location",
                         features: "Standard banner • Home screen rotation")
                planCard(.featured, desc: "Logo + contact info + amenities",
                         features: "Gold border • Featured badge • All screens")
                planCard(.premium,  desc: "Maximum visibility",
                         features: "Gold glow • Premium crown badge • Priority placement")
            }
        }
    }

    private func planCard(_ plan: GymAd.AdPlan, desc: String, features: String) -> some View {
        Button(action: { selectedPlan = plan }) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        if let badge = plan.badge {
                            Text(String(badge.prefix(1))).font(.system(size: 16))
                        }
                        Text(plan.rawValue.capitalized)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(selectedPlan == plan ? .black : .white)
                        Text(plan.displayPrice)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(selectedPlan == plan ? .black.opacity(0.6) : plan.borderColor)
                    }
                    Text(desc).font(.caption)
                        .foregroundColor(selectedPlan == plan ? .black.opacity(0.7) : .white.opacity(0.5))
                    Text(features).font(.system(size: 10))
                        .foregroundColor(selectedPlan == plan ? .black.opacity(0.5) : .white.opacity(0.3))
                }
                Spacer()
                if selectedPlan == plan {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.black).font(.title3)
                }
            }
            .padding(14)
            .background(selectedPlan == plan ? plan.borderColor : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(plan.borderColor.opacity(selectedPlan == plan ? 0 : 0.4), lineWidth: 1))
            .shadow(color: selectedPlan == plan ? plan.glowColor : .clear, radius: 6)
        }
        .buttonStyle(.plain)
    }

    private var logoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                formLabel("GYM LOGO / PHOTO")
                if !logoAllowed {
                    Text("(Featured & Premium only)")
                        .font(.caption2).foregroundColor(.white.opacity(0.3))
                }
            }
            if logoAllowed {
                PhotosPicker(selection: $selectedLogoItem, matching: .images) {
                    ZStack {
                        if let data = selectedLogoData, let img = UIImage(data: data) {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.tmGold, lineWidth: 2))
                        } else {
                            RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06))
                                .frame(width: 100, height: 100)
                                .overlay(VStack(spacing: 6) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.title2).foregroundColor(.tmGold)
                                    Text("Add Logo").font(.caption2).foregroundColor(.white.opacity(0.4))
                                })
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03))
                    .frame(width: 100, height: 100)
                    .overlay(VStack(spacing: 6) {
                        Image(systemName: "lock.fill").font(.title2).foregroundColor(.white.opacity(0.2))
                        Text("Upgrade plan").font(.caption2).foregroundColor(.white.opacity(0.25))
                    })
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var businessInfoSection: some View {
        VStack(spacing: 14) {
            field("BUSINESS NAME", placeholder: "e.g. Iron Body Fitness", text: $businessName)
            field("TAGLINE", placeholder: "e.g. Where champions train", text: $tagline)
            field("EMAIL (REQUIRED)", placeholder: "contact@yourgym.com", text: $email)
                .keyboardType(.emailAddress)
            VStack(alignment: .leading, spacing: 6) {
                formLabel("SECURITY PIN (4 digits — to edit your ad later)")
                HStack {
                    if showPin {
                        TextField("1234", text: $pin).keyboardType(.numberPad)
                            .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    } else {
                        SecureField("1234", text: $pin).keyboardType(.numberPad)
                            .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    }
                    Button(action: { showPin.toggle() }) {
                        Image(systemName: showPin ? "eye.slash" : "eye")
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                .onChange(of: pin) { _, v in pin = String(v.filter { $0.isNumber }.prefix(4)) }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            formLabel("CATEGORY")
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(GymCategory.allCases, id: \.self) { cat in
                    Button(action: { category = cat }) {
                        HStack(spacing: 6) {
                            Text(cat.icon).font(.system(size: 14))
                            Text(cat.label).font(.system(size: 11, weight: .bold))
                                .lineLimit(1)
                        }
                        .foregroundColor(category == cat ? .black : .white.opacity(0.6))
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(category == cat ? cat.accentColor : Color.white.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            formLabel("AMENITIES (SELECT ALL THAT APPLY)")
            FlowLayout(spacing: 8) {
                ForEach(gymAmenityOptions, id: \.self) { amenity in
                    let selected = selectedAmenities.contains(amenity)
                    Button(action: {
                        if selected { selectedAmenities.removeAll { $0 == amenity } }
                        else        { selectedAmenities.append(amenity) }
                    }) {
                        HStack(spacing: 4) {
                            if selected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10)).foregroundColor(.tmGold)
                            }
                            Text(amenity).font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(selected ? .black : .white.opacity(0.55))
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(Capsule().fill(selected ? Color.tmGold : Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            formLabel("LOCATION")
            field("STREET ADDRESS (OPTIONAL)", placeholder: "123 Fitness Blvd", text: $streetAddress)
            HStack(spacing: 10) {
                VStack(alignment: .leading) {
                    formLabel("CITY")
                    TextField("City", text: $city)
                        .foregroundColor(.white).padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                }
                VStack(alignment: .leading) {
                    formLabel("STATE")
                    TextField("ST", text: $state)
                        .foregroundColor(.white).padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                }
                .frame(width: 70)
                VStack(alignment: .leading) {
                    formLabel("ZIP")
                    TextField("00000", text: $zipCode).keyboardType(.numberPad)
                        .foregroundColor(.white).padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                }
                .frame(width: 90)
            }
        }
    }

    private var contactSection: some View {
        VStack(spacing: 14) {
            field("PHONE (OPTIONAL)", placeholder: "702-555-0100", text: $phone)
                .keyboardType(.phonePad)
            field("WEBSITE (OPTIONAL)", placeholder: "www.yourgym.com", text: $websiteURL)
                .keyboardType(.URL)
        }
    }

    private var nextStepsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill").foregroundColor(.tmGold)
                Text("WHAT HAPPENS NEXT").font(.system(size: 10, weight: .bold)).tracking(1)
                    .foregroundColor(.tmGold)
            }
            Text("Your listing will be reviewed within 24 hours. Once approved we'll contact you at \(email.isEmpty ? "your email" : email) to complete your \(selectedPlan.displayPrice) subscription via Stripe. Your ad goes live immediately after payment.")
                .font(.caption).foregroundColor(.white.opacity(0.5))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.tmGold.opacity(0.07))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.tmGold.opacity(0.2), lineWidth: 1)))
    }

    // MARK: Helpers

    @discardableResult
    private func field(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            formLabel(label)
            TextField(placeholder, text: text)
                .foregroundColor(.white).padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
        }
    }

    private func formLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
    }

    private func submit() async {
        isSubmitting = true
        var logoURL: String? = nil
        if logoAllowed, let data = selectedLogoData {
            let fileName = "gym-\(UUID().uuidString).jpg"
            logoURL = try? await manager.uploadImage(data: data, fileName: fileName)
        }
        let addressParts = [streetAddress, city, state, zipCode].filter { !$0.isEmpty }
        let fullAddress  = addressParts.joined(separator: ", ")
        let ad = GymAd(
            id: UUID(),
            businessName: businessName,
            tagline: tagline,
            category: category,
            phone: phone.isEmpty ? nil : phone,
            websiteURL: websiteURL.isEmpty ? nil : websiteURL,
            imageURL: logoURL,
            address: fullAddress.isEmpty ? nil : fullAddress,
            city: city.isEmpty ? nil : city,
            state: state.isEmpty ? nil : state,
            zipCode: zipCode.isEmpty ? nil : zipCode,
            latitude: nil, longitude: nil,
            status: .pending,
            plan: selectedPlan,
            advertiserEmail: email,
            advertiserPin: pin,
            paymentStatus: "unpaid",
            paidUntil: nil,
            amenities: selectedAmenities,
            notes: nil,
            createdAt: Date()
        )
        do {
            try await manager.submitAd(ad)
            await MainActor.run { isSubmitting = false; showSuccess = true }
        } catch {
            await MainActor.run { isSubmitting = false; errorMsg = error.localizedDescription; showError = true }
        }
    }
}
