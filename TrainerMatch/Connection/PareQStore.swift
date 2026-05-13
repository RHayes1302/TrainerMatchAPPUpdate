//
//  PAReQStore.swift
//  TrainerMatch
//
//  PAR-Q (Physical Activity Readiness Questionnaire) system.
//  Trainer requests → client completes via dropdown selections → trainer reviews with flags.
//

import SwiftUI

// MARK: - Models

struct PARQForm: Identifiable, Codable {
    let id: String
    var trainerId:    String
    var clientId:     String
    var clientName:   String
    var requestedAt:  Date
    var submittedAt:  Date?
    var status:       PARQStatus
    var answers:      [PARQAnswer]
    var fitnessBackground: FitnessBackground?

    enum PARQStatus: String, Codable {
        case pending   = "Pending"
        case completed = "Completed"
        case reviewed  = "Reviewed"
    }

    var isSubmitted: Bool { status != .pending }

    var flaggedAnswers: [PARQAnswer] {
        answers.filter { $0.isFlagged }
    }

    var hasConcerns: Bool { !flaggedAnswers.isEmpty }

    var riskLevel: RiskLevel {
        let count = flaggedAnswers.count
        if count == 0 { return .low }
        if count <= 2 { return .moderate }
        return .high
    }

    enum RiskLevel {
        case low, moderate, high
        var label: String {
            switch self {
            case .low:      return "Low Risk"
            case .moderate: return "Moderate Risk"
            case .high:     return "High Risk"
            }
        }
        var color: Color {
            switch self {
            case .low:      return .green
            case .moderate: return .orange
            case .high:     return .red
            }
        }
        var icon: String {
            switch self {
            case .low:      return "checkmark.shield.fill"
            case .moderate: return "exclamationmark.shield.fill"
            case .high:     return "xmark.shield.fill"
            }
        }
    }

    init(trainerId: String, clientId: String, clientName: String) {
        self.id          = UUID().uuidString
        self.trainerId   = trainerId
        self.clientId    = clientId
        self.clientName  = clientName
        self.requestedAt = Date()
        self.submittedAt = nil
        self.status      = .pending
        self.answers     = PARQQuestion.allCases.map { PARQAnswer(question: $0) }
        self.fitnessBackground = nil
    }
}

struct PARQAnswer: Identifiable, Codable {
    let id: String
    let question: PARQQuestion
    var response: PARQResponse
    var detail:   String?

    var isFlagged: Bool { response == .yes && question.flagOnYes ||
                          response == .no  && question.flagOnNo  }

    var concernMessage: String? {
        guard isFlagged else { return nil }
        return question.concernMessage
    }

    init(question: PARQQuestion) {
        self.id       = UUID().uuidString
        self.question = question
        self.response = .unanswered
        self.detail   = nil
    }
}

enum PARQResponse: String, Codable, CaseIterable {
    case yes        = "Yes"
    case no         = "No"
    case unanswered = "Select"
}

enum PARQQuestion: String, Codable, CaseIterable {
    // Standard PAR-Q 7 questions
    case heartCondition   = "heartCondition"
    case chestPainActive  = "chestPainActive"
    case chestPainRest    = "chestPainRest"
    case dizziness        = "dizziness"
    case boneJoint        = "boneJoint"
    case bloodPressure    = "bloodPressure"
    case otherReason      = "otherReason"

    var number: Int {
        switch self {
        case .heartCondition:  return 1
        case .chestPainActive: return 2
        case .chestPainRest:   return 3
        case .dizziness:       return 4
        case .boneJoint:       return 5
        case .bloodPressure:   return 6
        case .otherReason:     return 7
        }
    }

    var questionText: String {
        switch self {
        case .heartCondition:
            return "Has your doctor ever said that you have a heart condition and that you should only do physical activity recommended by a doctor?"
        case .chestPainActive:
            return "Do you feel pain in your chest when you do physical activity?"
        case .chestPainRest:
            return "In the past month, have you had chest pain when you were not doing physical activity?"
        case .dizziness:
            return "Do you lose your balance because of dizziness or do you ever lose consciousness?"
        case .boneJoint:
            return "Do you have a bone or joint problem (for example, back, knee or hip) that could be made worse by a change in your physical activity?"
        case .bloodPressure:
            return "Is your doctor currently prescribing drugs (for example, water pills) for your blood pressure or heart condition?"
        case .otherReason:
            return "Do you know of any other reason why you should not do physical activity?"
        }
    }

    var shortLabel: String {
        switch self {
        case .heartCondition:  return "Heart Condition"
        case .chestPainActive: return "Chest Pain (active)"
        case .chestPainRest:   return "Chest Pain (rest)"
        case .dizziness:       return "Dizziness / Fainting"
        case .boneJoint:       return "Bone / Joint Issues"
        case .bloodPressure:   return "Blood Pressure Meds"
        case .otherReason:     return "Other Health Reason"
        }
    }

    // Flag if client answers YES to these
    var flagOnYes: Bool { true } // All 7 standard questions flag on Yes

    // Flag if client answers NO to these (none in standard PAR-Q)
    var flagOnNo: Bool { false }

    var concernMessage: String {
        switch self {
        case .heartCondition:
            return "Client has a heart condition. Medical clearance from a physician is recommended before beginning an exercise program."
        case .chestPainActive:
            return "Client experiences chest pain during physical activity. Consult a physician before proceeding with exercise."
        case .chestPainRest:
            return "Client has experienced chest pain at rest in the past month. Physician evaluation is strongly recommended."
        case .dizziness:
            return "Client has reported dizziness or loss of consciousness. Monitor closely and consult a physician."
        case .boneJoint:
            return "Client has bone or joint issues that may be aggravated by exercise. Modify program accordingly."
        case .bloodPressure:
            return "Client is on blood pressure or heart medication. Be aware of exercise intensity limits and potential interactions."
        case .otherReason:
            return "Client has indicated another health reason that may affect physical activity. Review details with client before programming."
        }
    }

    var icon: String {
        switch self {
        case .heartCondition:  return "heart.fill"
        case .chestPainActive: return "bolt.heart.fill"
        case .chestPainRest:   return "heart.slash.fill"
        case .dizziness:       return "brain.head.profile"
        case .boneJoint:       return "figure.walk"
        case .bloodPressure:   return "pill.fill"
        case .otherReason:     return "exclamationmark.circle.fill"
        }
    }

    var detailPrompt: String {
        switch self {
        case .heartCondition:  return "What is the condition? Any restrictions given?"
        case .chestPainActive: return "When does pain occur? Location?"
        case .chestPainRest:   return "How often? Any other symptoms?"
        case .dizziness:       return "How often? Any known cause?"
        case .boneJoint:       return "Which area(s)? Any surgeries or therapy?"
        case .bloodPressure:   return "What medication(s)?"
        case .otherReason:     return "Please describe"
        }
    }
}

struct FitnessBackground: Codable {
    var activityLevel:    ActivityFrequency = .notSelected
    var exerciseTypes:    [ExerciseType]    = []
    var fitnessGoal:      FitnessGoalType   = .notSelected
    var injuryHistory:    InjuryHistory     = .notSelected
    var injuryDetail:     String            = ""
    var smokingStatus:    SmokingStatus     = .notSelected
    var pregnantOrRecent: PregnancyStatus   = .notSelected

    enum ActivityFrequency: String, Codable, CaseIterable {
        case notSelected     = "Select"
        case sedentary       = "Sedentary (little to no exercise)"
        case lightlyActive   = "Lightly active (1–2 days/week)"
        case moderatelyActive = "Moderately active (3–4 days/week)"
        case veryActive      = "Very active (5+ days/week)"
        case athlete         = "Competitive athlete"
    }

    enum ExerciseType: String, Codable, CaseIterable {
        case cardio          = "Cardio"
        case weightTraining  = "Weight Training"
        case yoga            = "Yoga / Pilates"
        case sports          = "Sports"
        case swimming        = "Swimming"
        case cycling         = "Cycling"
        case hiit            = "HIIT"
        case none            = "None currently"
    }

    enum FitnessGoalType: String, Codable, CaseIterable {
        case notSelected     = "Select"
        case weightLoss      = "Weight Loss"
        case muscleGain      = "Muscle Gain"
        case endurance       = "Endurance / Stamina"
        case flexibility     = "Flexibility / Mobility"
        case generalHealth   = "General Health & Fitness"
        case athleticPerf    = "Athletic Performance"
        case rehabilitation  = "Rehabilitation / Recovery"
    }

    enum InjuryHistory: String, Codable, CaseIterable {
        case notSelected     = "Select"
        case none            = "No injuries"
        case pastMinor       = "Past minor injuries (healed)"
        case pastMajor       = "Past major injuries (healed)"
        case currentMinor    = "Current minor issue"
        case currentMajor    = "Current significant injury"
    }

    enum SmokingStatus: String, Codable, CaseIterable {
        case notSelected     = "Select"
        case never           = "Never smoked"
        case former          = "Former smoker"
        case current         = "Current smoker"
    }

    enum PregnancyStatus: String, Codable, CaseIterable {
        case notSelected     = "Select"
        case notApplicable   = "Not applicable"
        case no              = "No"
        case yes             = "Currently pregnant"
        case recentlyPostpartum = "Recently postpartum (< 6 months)"
    }
}

// MARK: - Store

class PARQStore: ObservableObject {
    static let shared = PARQStore()
    @Published var forms: [PARQForm] = []

    private var url: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("parqForms.json")
    }

    private init() { load() }

    // MARK: Queries

    func forms(forClient id: String) -> [PARQForm] {
        forms.filter { $0.clientId == id }.sorted { $0.requestedAt > $1.requestedAt }
    }

    func forms(forTrainer id: String) -> [PARQForm] {
        forms.filter { $0.trainerId == id }.sorted { $0.requestedAt > $1.requestedAt }
    }

    func latestForm(forClient id: String) -> PARQForm? {
        forms(forClient: id).first
    }

    func pendingForm(forClient id: String, trainerId: String) -> PARQForm? {
        forms.first { $0.clientId == id && $0.trainerId == trainerId && $0.status == .pending }
    }

    // MARK: Actions

    func requestForm(trainerId: String, clientId: String, clientName: String) {
        // Only one pending at a time
        guard pendingForm(forClient: clientId, trainerId: trainerId) == nil else { return }
        let form = PARQForm(trainerId: trainerId, clientId: clientId, clientName: clientName)
        forms.insert(form, at: 0)
        save()
        NotificationManager.shared.send(
            recipientId: clientId, recipientRole: .client,
            senderId: trainerId, senderName: "Your Trainer",
            category: .message,
            title: "PAR-Q Health Form Requested",
            body: "Your trainer has requested you complete a Physical Activity Readiness Questionnaire."
        )
    }

    func submit(_ form: PARQForm) {
        var updated       = form
        updated.status    = .completed
        updated.submittedAt = Date()
        upsert(updated)
        NotificationManager.shared.send(
            recipientId: form.trainerId, recipientRole: .trainer,
            senderId: form.clientId, senderName: form.clientName,
            category: .checkIn,
            title: "\(form.clientName) completed their PAR-Q",
            body: updated.hasConcerns
                ? "⚠️ \(updated.flaggedAnswers.count) concern(s) flagged — review required."
                : "✓ No health concerns flagged."
        )
    }

    func markReviewed(_ form: PARQForm) {
        var updated    = form
        updated.status = .reviewed
        upsert(updated)
    }

    private func upsert(_ form: PARQForm) {
        if let i = forms.firstIndex(where: { $0.id == form.id }) {
            forms[i] = form
        } else {
            forms.insert(form, at: 0)
        }
        save()
    }

    private func save() {
        try? JSONEncoder().encode(forms).write(to: url)
    }

    private func load() {
        if let d = try? Data(contentsOf: url),
           let f = try? JSONDecoder().decode([PARQForm].self, from: d) {
            forms = f
        }
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: CLIENT: PAR-Q FORM VIEW
// MARK: ─────────────────────────────────────────────

struct ClientPARQFormView: View {
    let form:      PARQForm
    let onSubmit:  () -> Void
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = PARQStore.shared

    @State private var answers:    [PARQAnswer]
    @State private var background: FitnessBackground
    @State private var currentPage = 0   // 0 = PAR-Q questions, 1 = fitness background, 2 = review
    @State private var showingConfirm = false

    init(form: PARQForm, onSubmit: @escaping () -> Void) {
        self.form     = form
        self.onSubmit = onSubmit
        _answers    = State(initialValue: form.answers)
        _background = State(initialValue: form.fitnessBackground ?? FitnessBackground())
    }

    private var allAnswered: Bool {
        answers.allSatisfy { $0.response != .unanswered }
    }

    private var flaggedCount: Int { answers.filter { $0.isFlagged }.count }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Progress bar
                progressHeader
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if currentPage == 0 { parqPage }
                        else if currentPage == 1 { backgroundPage }
                        else { reviewPage }
                    }
                    .padding(20)
                }
                // Bottom nav
                bottomNav
            }
        }
        .navigationTitle("PAR-Q Health Form")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .confirmationDialog(
            flaggedCount > 0
                ? "You answered Yes to \(flaggedCount) question(s). Your trainer will be notified of these concerns. Submit anyway?"
                : "Submit your completed PAR-Q form to your trainer?",
            isPresented: $showingConfirm,
            titleVisibility: .visible
        ) {
            Button("Submit Form", role: .none) { submitForm() }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: Progress header

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(i <= currentPage ? Color.tmGold : Color.white.opacity(0.15))
                        .frame(maxWidth: .infinity).frame(height: 4)
                }
            }
            .padding(.horizontal, 20).padding(.top, 12)
            HStack {
                Text(["PAR-Q Questions", "Fitness Background", "Review & Submit"][currentPage])
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("Step \(currentPage + 1) of 3")
                    .font(.caption).foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 20).padding(.bottom, 8)
            Divider().background(Color.white.opacity(0.08))
        }
    }

    // MARK: Page 1 — PAR-Q Questions

    private var parqPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title2).foregroundColor(.tmGold)
                    Text("Physical Activity Readiness")
                        .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                }
                Text("Please answer all 7 questions honestly. These help your trainer design the safest program for you.")
                    .font(.caption).foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14)
                .fill(Color.tmGold.opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.tmGold.opacity(0.2), lineWidth: 1)))

            ForEach($answers) { $answer in
                PARQQuestionCard(answer: $answer)
            }
        }
    }

    // MARK: Page 2 — Fitness Background

    private var backgroundPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Fitness Background")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Text("Help your trainer understand your experience and goals.")
                    .font(.caption).foregroundColor(.white.opacity(0.5))
            }

            // Activity level
            bgSection("Current Activity Level", icon: "figure.run") {
                AnyView(DropdownPicker(
                    selection: $background.activityLevel,
                    options: FitnessBackground.ActivityFrequency.allCases,
                    label: { $0.rawValue }
                ))
            }

            // Exercise types (multi-select)
            bgSection("Types of Exercise", icon: "dumbbell.fill") {
                AnyView(MultiSelectChips(
                    selected: $background.exerciseTypes,
                    options: FitnessBackground.ExerciseType.allCases,
                    label: { $0.rawValue }
                ))
            }

            // Primary goal
            bgSection("Primary Fitness Goal", icon: "target") {
                AnyView(DropdownPicker(
                    selection: $background.fitnessGoal,
                    options: FitnessBackground.FitnessGoalType.allCases,
                    label: { $0.rawValue }
                ))
            }

            // Injury history
            bgSection("Injury History", icon: "bandage.fill") {
                AnyView(VStack(spacing: 8) {
                    DropdownPicker(
                        selection: $background.injuryHistory,
                        options: FitnessBackground.InjuryHistory.allCases,
                        label: { $0.rawValue }
                    )
                    if background.injuryHistory == .currentMinor ||
                       background.injuryHistory == .currentMajor ||
                       background.injuryHistory == .pastMajor {
                        TextField("Describe the injury/area...", text: $background.injuryDetail, axis: .vertical)
                            .foregroundColor(.white).lineLimit(2...4).padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                    }
                })
            }

            // Smoking
            bgSection("Smoking Status", icon: "lungs.fill") {
                AnyView(DropdownPicker(
                    selection: $background.smokingStatus,
                    options: FitnessBackground.SmokingStatus.allCases,
                    label: { $0.rawValue }
                ))
            }

            // Pregnancy
            bgSection("Pregnancy / Postpartum", icon: "figure.pregnant") {
                AnyView(DropdownPicker(
                    selection: $background.pregnantOrRecent,
                    options: FitnessBackground.PregnancyStatus.allCases,
                    label: { $0.rawValue }
                ))
            }
        }
    }

    // MARK: Page 3 — Review

    private var reviewPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Risk summary
            riskSummaryCard

            // Flagged concerns
            if flaggedCount > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("⚠️ FLAGGED CONCERNS (\(flaggedCount))")
                    ForEach(answers.filter { $0.isFlagged }) { answer in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: answer.question.icon)
                                .foregroundColor(.orange).frame(width: 20)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(answer.question.shortLabel)
                                    .font(.system(size: 13, weight: .bold)).foregroundColor(.orange)
                                Text(answer.concernMessage ?? "")
                                    .font(.caption).foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.25), lineWidth: 1)))
                    }
                }
            }

            // All answers summary
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("ALL ANSWERS")
                ForEach(answers) { answer in
                    HStack(spacing: 12) {
                        Text("Q\(answer.question.number)")
                            .font(.system(size: 10, weight: .black)).foregroundColor(.tmGold)
                            .frame(width: 24)
                        Text(answer.question.shortLabel)
                            .font(.system(size: 13)).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading)
                        Text(answer.response.rawValue)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(answer.isFlagged ? .orange : answer.response == .no ? .green : .white.opacity(0.5))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(
                                answer.isFlagged ? Color.orange.opacity(0.15) :
                                answer.response == .no ? Color.green.opacity(0.12) :
                                Color.white.opacity(0.06)))
                    }
                    .padding(.vertical, 6).padding(.horizontal, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.03)))
                }
            }

            // Disclaimer
            Text("By submitting this form I confirm that the information provided is accurate to the best of my knowledge. This questionnaire does not replace professional medical advice.")
                .font(.caption2).foregroundColor(.white.opacity(0.3))
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.03)))
        }
    }

    private var riskSummaryCard: some View {
        let risk = computeRiskLevel()
        return HStack(spacing: 14) {
            Image(systemName: risk.icon).font(.system(size: 32)).foregroundColor(risk.color)
            VStack(alignment: .leading, spacing: 4) {
                Text(risk.label).font(.system(size: 18, weight: .black)).foregroundColor(risk.color)
                Text(flaggedCount == 0
                     ? "No health concerns identified. You're cleared to begin."
                     : "\(flaggedCount) concern(s) will be flagged for your trainer.")
                    .font(.caption).foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14)
            .fill(risk.color.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(risk.color.opacity(0.3), lineWidth: 1)))
    }

    // MARK: Bottom nav

    private var bottomNav: some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.08))
            HStack(spacing: 12) {
                if currentPage > 0 {
                    Button(action: { withAnimation { currentPage -= 1 } }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(.tmGold)
                        .frame(width: 100).frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 25)
                            .fill(Color.tmGold.opacity(0.08)))
                    }
                }

                Button(action: {
                    if currentPage < 2 {
                        withAnimation { currentPage += 1 }
                    } else {
                        showingConfirm = true
                    }
                }) {
                    HStack(spacing: 8) {
                        if currentPage == 2 {
                            Image(systemName: "paperplane.fill")
                        }
                        Text(currentPage == 2 ? "SUBMIT FORM" : "CONTINUE")
                            .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                    }
                    .foregroundColor(currentPage == 0 && !allAnswered ? .white.opacity(0.4) : .black)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 25)
                        .fill(currentPage == 0 && !allAnswered
                              ? Color.white.opacity(0.08)
                              : Color.tmGold))
                }
                .disabled(currentPage == 0 && !allAnswered)
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
        .background(Color.black)
    }

    // MARK: Helpers

    private func bgSection(_ title: String, icon: String, @ViewBuilder content: () -> AnyView) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption).foregroundColor(.tmGold)
                Text(title).font(.system(size: 12, weight: .bold)).tracking(0.5).foregroundColor(.tmGold)
            }
            content()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
    }

    private func computeRiskLevel() -> PARQForm.RiskLevel {
        let count = answers.filter { $0.isFlagged }.count
        if count == 0 { return .low }
        if count <= 2 { return .moderate }
        return .high
    }

    private func submitForm() {
        var updated           = form
        updated.answers       = answers
        updated.fitnessBackground = background
        store.submit(updated)
        onSubmit()
        dismiss()
    }
}

// MARK: - PAR-Q Question Card

struct PARQQuestionCard: View {
    @Binding var answer: PARQAnswer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(answer.isFlagged ? Color.orange.opacity(0.2) : Color.tmGold.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Text("Q\(answer.question.number)")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(answer.isFlagged ? .orange : .tmGold)
                }
                Text(answer.question.questionText)
                    .font(.system(size: 14)).foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Yes / No selector
            HStack(spacing: 10) {
                responseButton("No",  selected: answer.response == .no,  isFlagged: false) {
                    answer.response = .no
                    answer.detail   = nil
                }
                responseButton("Yes", selected: answer.response == .yes, isFlagged: answer.response == .yes) {
                    answer.response = .yes
                }
            }

            // Detail field if Yes
            if answer.response == .yes {
                VStack(alignment: .leading, spacing: 6) {
                    Text(answer.question.detailPrompt)
                        .font(.caption2).foregroundColor(.orange.opacity(0.8))
                    TextField("Optional — add details...", text: Binding(
                        get: { answer.detail ?? "" },
                        set: { answer.detail = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .foregroundColor(.white).lineLimit(2...4).padding(10)
                    .font(.caption)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.25), lineWidth: 1)))
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        let fillColor:   Color  = answer.isFlagged ? Color.orange.opacity(0.06) : Color.white.opacity(0.04)
        let strokeColor: Color  = answer.isFlagged ? Color.orange.opacity(0.3)  : Color.white.opacity(0.07)
        let lineWidth:   CGFloat = answer.isFlagged ? 1.5 : 1.0
        return RoundedRectangle(cornerRadius: 14)
            .fill(fillColor)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(strokeColor, lineWidth: lineWidth))
    }

    private func responseButton(_ label: String, selected: Bool, isFlagged: Bool,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: selected
                      ? (label == "No" ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                      : "circle")
                    .foregroundColor(selected ? (isFlagged ? .orange : .green) : .white.opacity(0.3))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(selected ? (isFlagged ? .orange : .green) : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity).frame(height: 42)
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(selected
                      ? (isFlagged ? Color.orange.opacity(0.1) : Color.green.opacity(0.1))
                      : Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(selected
                            ? (isFlagged ? Color.orange.opacity(0.5) : Color.green.opacity(0.5))
                            : Color.white.opacity(0.08), lineWidth: 1.5)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reusable Dropdown Picker

struct DropdownPicker<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
    @Binding var selection: T
    let options: [T]
    let label: (T) -> String

    var body: some View {
        Menu {
            ForEach(Array(options), id: \.self) { opt in
                Button(label(opt)) { selection = opt }
            }
        } label: {
            HStack {
                Text(label(selection))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(label(selection) == "Select" ? .white.opacity(0.3) : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption).foregroundColor(.tmGold)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.tmGold.opacity(0.2), lineWidth: 1)))
        }
    }
}

// MARK: - Multi-Select Chips

struct MultiSelectChips<T: RawRepresentable & CaseIterable & Hashable & Equatable>: View where T.RawValue == String {
    @Binding var selected: [T]
    let options: [T]
    let label: (T) -> String

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(options), id: \.self) { opt in
                let isSelected = selected.contains(opt)
                Button(action: {
                    if isSelected { selected.removeAll { $0 == opt } }
                    else          { selected.append(opt) }
                }) {
                    Text(label(opt))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? .black : .white.opacity(0.55))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(isSelected ? Color.tmGold : Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// Simple flow layout for chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0; var y: CGFloat = 0; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > width && x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
        return CGSize(width: width, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX && x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: TRAINER: PAR-Q SUMMARY CARD (for client folder)
// MARK: ─────────────────────────────────────────────

struct TrainerPARQSummaryCard: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @ObservedObject private var store = PARQStore.shared
    @State private var showingForm:    PARQForm? = nil
    @State private var showingRequest  = false

    private var latest: PARQForm? { store.latestForm(forClient: clientId) }
    private var pending: Bool {
        store.pendingForm(forClient: clientId, trainerId: trainerId) != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.caption).foregroundColor(.tmGold)
                    Text("PAR-Q HEALTH FORM").font(.system(size: 11, weight: .bold))
                        .tracking(1.2).foregroundColor(.tmGold)
                }
                Spacer()
                if let form = latest, form.isSubmitted {
                    Button("View") { showingForm = form }
                        .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                }
            }

            if let form = latest {
                if form.isSubmitted {
                    submittedCard(form)
                } else {
                    pendingCard
                }
            } else {
                noFormCard
            }
        }
        .sheet(item: $showingForm) { form in
            NavigationView {
                TrainerPARQReviewView(form: form)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
        .confirmationDialog(
            "Send PAR-Q request to \(clientName)?",
            isPresented: $showingRequest,
            titleVisibility: .visible
        ) {
            Button("Send Request") {
                store.requestForm(trainerId: trainerId, clientId: clientId, clientName: clientName)
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func submittedCard(_ form: PARQForm) -> some View {
        let strokeColor: Color = form.hasConcerns ? Color.orange.opacity(0.3) : Color.white.opacity(0.07)
        return Button(action: { showingForm = form }) {
            VStack(spacing: 10) {
                submittedCardHeader(form)
                if form.hasConcerns {
                    submittedCardConcerns(form)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(strokeColor, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    private func submittedCardHeader(_ form: PARQForm) -> some View {
        HStack(spacing: 10) {
            Image(systemName: form.riskLevel.icon)
                .font(.system(size: 22)).foregroundColor(form.riskLevel.color)
            VStack(alignment: .leading, spacing: 3) {
                Text(form.riskLevel.label)
                    .font(.system(size: 14, weight: .black)).foregroundColor(form.riskLevel.color)
                if let date = form.submittedAt {
                    Text("Submitted \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2).foregroundColor(.white.opacity(0.4))
                }
            }
            Spacer()
            if form.status == .completed {
                Text("NEW").font(.system(size: 9, weight: .black)).foregroundColor(.black)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color.tmGold))
            }
        }
    }

    private func submittedCardConcerns(_ form: PARQForm) -> some View {
        VStack(spacing: 6) {
            ForEach(form.flaggedAnswers.prefix(2)) { answer in
                HStack(spacing: 8) {
                    Image(systemName: answer.question.icon)
                        .font(.caption2).foregroundColor(.orange).frame(width: 16)
                    Text(answer.question.shortLabel)
                        .font(.caption2).foregroundColor(.orange)
                    Spacer()
                }
            }
            if form.flaggedAnswers.count > 2 {
                Text("+\(form.flaggedAnswers.count - 2) more concerns — tap to view all")
                    .font(.caption2).foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.07)))
    }

    private var pendingCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.fill").foregroundColor(.tmGold.opacity(0.5))
            Text("PAR-Q requested — awaiting client response")
                .font(.caption).foregroundColor(.white.opacity(0.4))
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.tmGold.opacity(0.15), lineWidth: 1)))
    }

    private var noFormCard: some View {
        Button(action: { showingRequest = true }) {
            HStack(spacing: 12) {
                Image(systemName: "heart.text.square").font(.title3)
                    .foregroundColor(.tmGold.opacity(0.4))
                VStack(alignment: .leading, spacing: 2) {
                    Text("No PAR-Q on file").font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.5))
                    Text("Tap to request client complete health form")
                        .font(.caption).foregroundColor(.white.opacity(0.3))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption)
                    .foregroundColor(.tmGold.opacity(0.4))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.tmGold.opacity(0.15), lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trainer: Full PAR-Q Review View

struct TrainerPARQReviewView: View {
    let form: PARQForm
    @ObservedObject private var store = PARQStore.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Risk banner
                    riskBanner

                    // Flagged concerns
                    if form.hasConcerns {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("⚠️ FLAGGED CONCERNS (\(form.flaggedAnswers.count))")
                            ForEach(form.flaggedAnswers) { answer in
                                concernCard(answer)
                            }
                        }
                    }

                    // Full PAR-Q answers
                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("FULL PAR-Q ANSWERS")
                        ForEach(form.answers) { answer in
                            fullAnswerRow(answer)
                        }
                    }

                    // Fitness background
                    if let bg = form.fitnessBackground {
                        fitnessBackgroundSection(bg)
                    }

                    // Submitted info
                    if let date = form.submittedAt {
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(.tmGold)
                            Text("Submitted by \(form.clientName) on \(date.formatted(date: .long, time: .shortened))")
                                .font(.caption).foregroundColor(.white.opacity(0.4))
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.03)))
                    }

                    // Mark reviewed button
                    if form.status == .completed {
                        Button(action: {
                            store.markReviewed(form)
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("MARK AS REVIEWED")
                                    .font(.system(size: 15, weight: .heavy)).tracking(0.4)
                            }
                            .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 52)
                            .background(RoundedRectangle(cornerRadius: 26).fill(Color.tmGold))
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("PAR-Q — \(form.clientName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
    }

    private var riskBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: form.riskLevel.icon).font(.system(size: 36))
                .foregroundColor(form.riskLevel.color)
            VStack(alignment: .leading, spacing: 4) {
                Text(form.riskLevel.label)
                    .font(.system(size: 20, weight: .black)).foregroundColor(form.riskLevel.color)
                Text(form.hasConcerns
                     ? "\(form.flaggedAnswers.count) concern(s) flagged — review below"
                     : "No health concerns identified")
                    .font(.subheadline).foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16)
            .fill(form.riskLevel.color.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(form.riskLevel.color.opacity(0.3), lineWidth: 1.5)))
    }

    private func concernCard(_ answer: PARQAnswer) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: answer.question.icon).foregroundColor(.orange)
                Text(answer.question.shortLabel)
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.orange)
            }
            Text(answer.concernMessage ?? "")
                .font(.subheadline).foregroundColor(.white.opacity(0.7))
            if let detail = answer.detail, !detail.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "quote.bubble").font(.caption).foregroundColor(.tmGold.opacity(0.5))
                    Text("Client note: \(detail)").font(.caption).foregroundColor(.tmGold)
                }
                .padding(8).background(RoundedRectangle(cornerRadius: 8).fill(Color.tmGold.opacity(0.06)))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(Color.orange.opacity(0.07))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)))
    }

    private func fullAnswerRow(_ answer: PARQAnswer) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("Q\(answer.question.number)")
                .font(.system(size: 10, weight: .black)).foregroundColor(.tmGold)
                .frame(width: 24)
            Text(answer.question.shortLabel)
                .font(.system(size: 13)).foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(answer.response.rawValue)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(answer.isFlagged ? .orange : .green)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(
                    answer.isFlagged ? Color.orange.opacity(0.12) : Color.green.opacity(0.1)))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(answer.isFlagged ? Color.orange.opacity(0.04) : Color.white.opacity(0.03)))
    }

    private func fitnessBackgroundSection(_ bg: FitnessBackground) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("FITNESS BACKGROUND")
            bgRow("Activity Level",   bg.activityLevel.rawValue,      "figure.run")
            bgRow("Primary Goal",     bg.fitnessGoal.rawValue,         "target")
            bgRow("Injury History",   bg.injuryHistory.rawValue,       "bandage.fill")
            if !bg.injuryDetail.isEmpty {
                bgRow("Injury Detail", bg.injuryDetail, "text.bubble")
            }
            bgRow("Smoking Status",   bg.smokingStatus.rawValue,       "lungs.fill")
            bgRow("Pregnancy Status", bg.pregnantOrRecent.rawValue,    "figure.pregnant")
            if !bg.exerciseTypes.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "dumbbell.fill").font(.caption).foregroundColor(.tmGold).frame(width: 20)
                    Text("Exercise Types").font(.caption).foregroundColor(.white.opacity(0.4)).frame(width: 80, alignment: .leading)
                    FlowLayout(spacing: 6) {
                        ForEach(bg.exerciseTypes, id: \.self) { t in
                            Text(t.rawValue).font(.caption2).foregroundColor(.black)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Capsule().fill(Color.tmGold))
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)))
    }

    private func bgRow(_ label: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.caption).foregroundColor(.tmGold).frame(width: 20)
            Text(label).font(.caption).foregroundColor(.white.opacity(0.4)).frame(width: 110, alignment: .leading)
            Text(value).font(.caption).fontWeight(.semibold).foregroundColor(.white)
            Spacer()
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
    }
}

// MARK: - Client: PAR-Q Hub section

struct ClientPARQHubSection: View {
    let clientId:  String
    let trainerId: String
    @ObservedObject private var store = PARQStore.shared
    @State private var showingForm: PARQForm? = nil

    private var pending: PARQForm? {
        store.pendingForm(forClient: clientId, trainerId: trainerId)
    }
    private var latest: PARQForm? { store.latestForm(forClient: clientId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "heart.text.square.fill").font(.caption).foregroundColor(.tmGold)
                    Text("PAR-Q").font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                }
                Spacer()
                if let f = latest, f.isSubmitted {
                    Text("Completed").font(.caption2).fontWeight(.bold).foregroundColor(.green)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color.green.opacity(0.12)))
                }
            }

            if let form = pending {
                // Pending — CTA to complete
                Button(action: { showingForm = form }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.tmGold.opacity(0.15)).frame(width: 44, height: 44)
                            Image(systemName: "heart.text.square.fill").font(.system(size: 18))
                                .foregroundColor(.tmGold)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Health form requested").font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("Your trainer has requested you complete a PAR-Q. Tap to fill it out.")
                                .font(.caption).foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.tmGold)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14)
                        .fill(Color.tmGold.opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.tmGold.opacity(0.3), lineWidth: 1.5)))
                }
                .buttonStyle(.plain)
            } else if let form = latest, form.isSubmitted {
                // Completed summary
                HStack(spacing: 10) {
                    Image(systemName: form.riskLevel.icon).foregroundColor(form.riskLevel.color)
                    Text(form.riskLevel.label)
                        .font(.system(size: 13, weight: .bold)).foregroundColor(form.riskLevel.color)
                    Spacer()
                    if let date = form.submittedAt {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2).foregroundColor(.white.opacity(0.35))
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(form.riskLevel.color.opacity(0.07)))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "clock").foregroundColor(.white.opacity(0.3))
                    Text("No PAR-Q requested yet by your trainer")
                        .font(.caption).foregroundColor(.white.opacity(0.35))
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.03)))
            }
        }
        .sheet(item: $showingForm) { form in
            NavigationView {
                ClientPARQFormView(form: form) { }
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
