//
//  MissingViews.swift
//  TrainerMatch
//
//  Clean replacements for views that were in deleted store files.
//  Uses only types that actually exist in LegacyModels + SupabaseDataStores.
//

import SwiftUI
import PhotosUI

// MARK: - TrainerClientWeightSummary

struct TrainerClientWeightSummary: View {
    let clientId:   String
    let clientName: String
    @ObservedObject private var store = SBWeightStore.shared

    private var latest: SBWeightEntryRow? { store.latestWeight(forClient: clientId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "scalemass.fill").foregroundColor(.tmGold).font(.caption)
                Text("WEIGHT TRACKING")
                    .font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
            }

            if let entry = latest {
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Current").font(.caption).foregroundColor(.white.opacity(0.4))
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text(String(format: "%.1f", entry.weight))
                                .font(.system(size: 22, weight: .black)).foregroundColor(.tmGold)
                            Text(entry.unit).font(.caption).foregroundColor(.tmGold.opacity(0.6))
                        }
                        if let date = entry.loggedAt {
                            Text(date, style: .date).font(.caption2).foregroundColor(.white.opacity(0.3))
                        }
                    }
                    Spacer()
                    if !entry.note.isEmpty {
                        Text(entry.note).font(.caption).foregroundColor(.white.opacity(0.5)).lineLimit(2)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
            } else {
                Text("No weight logged yet.")
                    .font(.caption).foregroundColor(.white.opacity(0.4))
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
            }
        }
        .onAppear { store.loadForClient(clientId) }
    }
}

// MARK: - ClientWeightView

struct ClientWeightView: View {
    let clientId: String
    @ObservedObject private var store = SBWeightStore.shared
    @State private var showingLog     = false
    @State private var weightText     = ""
    @State private var unit           = "lbs"
    @State private var note           = ""
    @State private var isSaving       = false

    private var entries: [SBWeightEntryRow] { store.entries(forClient: clientId) }
    private var latest:  SBWeightEntryRow?  { entries.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Weight Tracking").font(.title2).fontWeight(.bold).foregroundColor(.white)
                Spacer()
                Button(action: { showingLog = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Weight")
                    }
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.black)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Color.tmGold))
                }
            }

            if let e = latest {
                HStack(spacing: 0) {
                    weightStat("Current", value: String(format: "%.1f", e.weight), unit: e.unit, color: .tmGold)
                    Divider().background(Color.white.opacity(0.1)).frame(height: 40)
                    weightStat("Entries", value: "\(entries.count)", unit: "total", color: .white)
                }
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "scalemass").font(.system(size: 36)).foregroundColor(.tmGold.opacity(0.3))
                    Text("No weight logged yet").foregroundColor(.white.opacity(0.4))
                    Text("Tap Log Weight to add your first entry")
                        .font(.caption).foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity).padding(30)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04)))
            }

            // Recent entries
            if !entries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RECENT").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                    ForEach(entries.prefix(5)) { e in
                        HStack {
                            if let d = e.loggedAt {
                                Text(d, style: .date).font(.subheadline).foregroundColor(.white)
                            }
                            Spacer()
                            Text(String(format: "%.1f %@", e.weight, e.unit))
                                .font(.system(size: 15, weight: .bold)).foregroundColor(.tmGold)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                    }
                }
            }
        }
        .onAppear { store.loadForClient(clientId) }
        .sheet(isPresented: $showingLog) {
            logWeightSheet
        }
    }

    private var logWeightSheet: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 24) {
                    TextField("0.0", text: $weightText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 52, weight: .black))
                        .foregroundColor(.tmGold).multilineTextAlignment(.center)

                    HStack(spacing: 0) {
                        ForEach(["lbs", "kg"], id: \.self) { u in
                            Button(action: { unit = u }) {
                                Text(u).font(.system(size: 13, weight: .bold))
                                    .foregroundColor(unit == u ? .black : .white.opacity(0.5))
                                    .padding(.horizontal, 24).padding(.vertical, 8)
                                    .background(unit == u ? Color.tmGold : Color.clear)
                            }
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.08)))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    TextField("Note (optional)", text: $note)
                        .foregroundColor(.white).padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))

                    Button(action: saveWeight) {
                        Text(isSaving ? "Saving..." : "SAVE")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 52)
                            .background(RoundedRectangle(cornerRadius: 26).fill(Color.tmGold))
                    }
                    .disabled(Double(weightText) == nil || isSaving)
                }
                .padding(24)
            }
            .navigationTitle("Log Weight").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showingLog = false }.foregroundColor(.tmGold)
                }
            }
        }
    }

    private func saveWeight() {
        guard let w = Double(weightText), let uid = UUID(uuidString: clientId) else { return }
        isSaving = true
        let entry = SBWeightEntryRow(
            id: UUID(), clientId: uid, trainerId: nil,
            weight: w, unit: unit, note: note, loggedAt: Date()
        )
        Task {
            try? await SBWeightStore.shared.log(entry)
            await MainActor.run {
                isSaving = false
                showingLog = false
                weightText = ""
                note = ""
            }
        }
    }

    private func weightStat(_ label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.system(size: 10, weight: .bold)).tracking(0.5).foregroundColor(.white.opacity(0.4))
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 22, weight: .black)).foregroundColor(color)
                if !unit.isEmpty {
                    Text(unit).font(.system(size: 11)).foregroundColor(color.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - TrainerClientMealPlanSummary

struct TrainerClientMealPlanSummary: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @ObservedObject private var store = SBMealPlanStore.shared
    @State private var showingPlans   = false
    @State private var showingBuilder = false

    private var plans:  [MealPlanRow] { store.plans(forClient: clientId) }
    private var active: MealPlanRow?  { store.activePlan(forClient: clientId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "fork.knife").foregroundColor(.tmGold).font(.caption)
                    Text("NUTRITION").font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                }
                Spacer()
                HStack(spacing: 10) {
                    Button(action: { showingBuilder = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill").font(.caption)
                            Text("Assign").font(.caption).fontWeight(.semibold)
                        }.foregroundColor(.tmGold)
                    }
                    if !plans.isEmpty {
                        Button("View All") { showingPlans = true }
                            .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                    }
                }
            }

            if plans.isEmpty {
                Button(action: { showingBuilder = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "fork.knife").font(.title3).foregroundColor(.tmGold.opacity(0.4))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No meal plan assigned")
                                .font(.subheadline).fontWeight(.semibold).foregroundColor(.white.opacity(0.5))
                            Text("Tap to build and assign a nutrition plan")
                                .font(.caption).foregroundColor(.white.opacity(0.3))
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.tmGold.opacity(0.4))
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tmGold.opacity(0.15), lineWidth: 1)))
                }
                .buttonStyle(.plain)
            } else if let p = active ?? plans.first {
                Button(action: { showingPlans = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(Color.tmGold.opacity(0.15)).frame(width: 38, height: 38)
                            Image(systemName: "fork.knife").font(.system(size: 14)).foregroundColor(.tmGold)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(p.title).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                            Text("\(p.dailyCalories) cal/day · \(p.meals.count) meals")
                                .font(.caption).foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                        if p.isActive {
                            Text("ACTIVE").font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(Color.tmGold))
                        }
                    }
                    .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingPlans) {
            NavigationView {
                TrainerClientMealPlansView(trainerId: trainerId, clientId: clientId, clientName: clientName)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(isPresented: $showingBuilder) {
            NavigationView {
                MealPlanBuilderView(trainerId: trainerId, clientId: clientId, clientName: clientName)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - ClientNutritionSection

struct ClientNutritionSection: View {
    let clientId:  String
    let clientName: String
    let trainerId: String
    @ObservedObject private var store = SBMealPlanStore.shared

    private var plans:  [MealPlanRow] { store.plans(forClient: clientId) }
    private var active: MealPlanRow?  { store.activePlan(forClient: clientId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition").font(.title2).fontWeight(.bold).foregroundColor(.white)

            if let p = active ?? plans.first {
                VStack(alignment: .leading, spacing: 10) {
                    Text(p.title).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    HStack(spacing: 0) {
                        macroCell("\(p.dailyCalories)", "kcal",   .tmGold)
                        macroCell(String(format: "%.0fg", p.proteinG), "protein", .red)
                        macroCell(String(format: "%.0fg", p.carbsG),   "carbs",   .blue)
                        macroCell(String(format: "%.0fg", p.fatG),     "fats",    .yellow)
                    }
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))

                    ForEach(p.meals.prefix(3)) { meal in
                        HStack {
                            Text(meal.mealType).font(.caption).foregroundColor(.tmGold).frame(width: 80, alignment: .leading)
                            Text(meal.name).font(.subheadline).foregroundColor(.white)
                            Spacer()
                            Text("\(meal.calories) cal").font(.caption).foregroundColor(.white.opacity(0.5))
                        }
                        .padding(10).background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife").font(.system(size: 40)).foregroundColor(.tmGold.opacity(0.2))
                    Text("No active meal plan").font(.subheadline).foregroundColor(.white.opacity(0.4))
                    Text("Your trainer hasn't assigned a nutrition plan yet.")
                        .font(.caption).foregroundColor(.white.opacity(0.3)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 24)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03)))
            }
        }
        .onAppear { store.loadForClient(clientId) }
    }

    private func macroCell(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 16, weight: .black)).foregroundColor(color)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - TrainerAllCheckInsForClientView

struct TrainerAllCheckInsForClientView: View {
    let clientId:   String
    let clientName: String
    @ObservedObject private var store = SBCheckInStore.shared

    private var checkIns: [CheckInRow] { store.checkIns(forClient: clientId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "camera.fill").font(.caption).foregroundColor(.tmGold)
                Text("CHECK-INS").font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                Spacer()
                Text("\(checkIns.count) total").font(.caption).foregroundColor(.white.opacity(0.4))
            }

            if checkIns.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "camera").foregroundColor(.white.opacity(0.2))
                    Text("No check-ins submitted yet")
                        .font(.caption).foregroundColor(.white.opacity(0.35))
                }
                .padding(12).background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.03)))
            } else {
                ForEach(checkIns.prefix(5)) { ci in
                    HStack(spacing: 12) {
                        // Photo thumbnail
                        if let url = ci.frontURL,
                           let data = try? Data(contentsOf: url),
                           let img  = UIImage(data: data) {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06))
                                .frame(width: 48, height: 48)
                                .overlay(Image(systemName: "camera").foregroundColor(.white.opacity(0.3)))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(ci.formattedDate)
                                .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                            Text(ci.formattedWeight).font(.caption).foregroundColor(.tmGold)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.3))
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
                }
            }
        }
        .onAppear { store.loadForClient(clientId) }
    }
}

// MARK: - ClientCheckInHistoryView

struct ClientCheckInHistoryView: View {
    let clientId: String
    @ObservedObject private var store = SBCheckInStore.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            let items = store.checkIns(forClient: clientId)
            if items.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "camera.viewfinder").font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.15)).padding(.top, 60)
                    Text("No check-ins yet").font(.title3).foregroundColor(.white.opacity(0.4))
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(items) { ci in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ci.formattedDate).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                    Text(ci.formattedWeight).font(.caption).foregroundColor(.tmGold)
                                    if !ci.notes.isEmpty {
                                        Text(ci.notes).font(.caption2).foregroundColor(.white.opacity(0.4))
                                    }
                                }
                                Spacer()
                                Text("\(ci.photoUrls.count) photos").font(.caption2).foregroundColor(.white.opacity(0.35))
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("My Check-Ins").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").fontWeight(.semibold)
                        Text("Back")
                    }.foregroundColor(.tmGold)
                }
            }
        }
        .onAppear { store.loadForClient(clientId) }
    }
}

// MARK: - ClientSubmitCheckInView

struct ClientSubmitCheckInView: View {
    let clientId:   String
    let clientName: String
    let trainerId:  String
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = SBCheckInStore.shared

    @State private var frontItem:   PhotosPickerItem?
    @State private var rearItem:    PhotosPickerItem?
    @State private var rightItem:   PhotosPickerItem?
    @State private var leftItem:    PhotosPickerItem?
    @State private var frontImage:  UIImage?
    @State private var rearImage:   UIImage?
    @State private var rightImage:  UIImage?
    @State private var leftImage:   UIImage?
    @State private var weightText   = ""
    @State private var unit         = "lbs"
    @State private var notes        = ""
    @State private var isSaving     = false
    @State private var showSuccess  = false

    private var canSubmit: Bool { Double(weightText) != nil }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Photos grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        photoCell("Front", item: $frontItem, image: $frontImage)
                        photoCell("Rear",  item: $rearItem,  image: $rearImage)
                        photoCell("Right", item: $rightItem, image: $rightImage)
                        photoCell("Left",  item: $leftItem,  image: $leftImage)
                    }

                    // Weight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MORNING WEIGHT").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                        HStack {
                            TextField("0.0", text: $weightText).keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .black)).foregroundColor(.tmGold)
                            Spacer()
                            HStack(spacing: 0) {
                                ForEach(["lbs","kg"], id: \.self) { u in
                                    Button(action: { unit = u }) {
                                        Text(u).font(.system(size: 12, weight: .bold))
                                            .foregroundColor(unit == u ? .black : .white.opacity(0.5))
                                            .padding(.horizontal, 14).padding(.vertical, 7)
                                            .background(unit == u ? Color.tmGold : Color.clear)
                                    }
                                }
                            }
                            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.08)))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .padding(14).background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTE (OPTIONAL)").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                        TextField("How are you feeling?", text: $notes, axis: .vertical)
                            .foregroundColor(.white).lineLimit(3...5).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    }

                    // Submit
                    Button(action: submit) {
                        HStack(spacing: 8) {
                            if isSaving { ProgressView().tint(.black) }
                            else {
                                Image(systemName: "paperplane.fill")
                                Text("SUBMIT CHECK-IN").font(.system(size: 15, weight: .heavy)).tracking(0.5)
                            }
                        }
                        .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 27)
                            .fill(canSubmit ? Color.tmGold : Color.tmGold.opacity(0.3)))
                    }
                    .disabled(!canSubmit || isSaving)
                }
                .padding(20)
            }
        }
        .navigationTitle("Weekly Check-In").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .alert("Check-In Submitted! ✅", isPresented: $showSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your trainer will review your progress soon.")
        }
    }

    private func photoCell(_ label: String, item: Binding<PhotosPickerItem?>, image: Binding<UIImage?>) -> some View {
        PhotosPicker(selection: item, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(image.wrappedValue != nil ? Color.tmGold.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1))
                    .frame(height: 140)
                if let img = image.wrappedValue {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(height: 140).clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill").font(.title2).foregroundColor(.white.opacity(0.3))
                        Text(label).font(.system(size: 13, weight: .bold)).foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
        .onChange(of: item.wrappedValue) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    image.wrappedValue = UIImage(data: data)
                }
            }
        }
    }

    private func submit() {
        guard let w = Double(weightText), let clientUUID = UUID(uuidString: clientId),
              let trainerUUID = UUID(uuidString: trainerId) else { return }
        isSaving = true

        // Collect photo data
        var photoData: [Data] = []
        for img in [frontImage, rearImage, rightImage, leftImage].compactMap({ $0 }) {
            if let d = img.jpegData(compressionQuality: 0.7) { photoData.append(d) }
        }

        let row = CheckInRow(
            id: UUID(), trainerId: trainerUUID, clientId: clientUUID,
            weight: w, notes: notes, photoUrls: [],
            energyLevel: nil, sleepHours: nil, waterOz: nil,
            checkedInAt: Date(), createdAt: Date()
        )

        Task {
            try? await SBCheckInStore.shared.submit(row, photos: photoData)
            await MainActor.run { isSaving = false; showSuccess = true }
        }
    }
}
