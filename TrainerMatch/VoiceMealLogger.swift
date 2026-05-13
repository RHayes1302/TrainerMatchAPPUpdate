//
//  VoiceMealLogger.swift
//  TrainerMatch
//
//  Client taps mic → speaks their meal → Claude AI parses it into
//  structured nutrition data → saved to Supabase meal_logs table.
//
//  Requirements:
//  - Add NSMicrophoneUsageDescription to Info.plist
//  - Add NSSpeechRecognitionUsageDescription to Info.plist
//  - Import Speech framework in Xcode target
//

import SwiftUI
import Speech
import AVFoundation

// MARK: - Meal Log Model

struct MealLogEntry: Codable, Identifiable {
    var id:           UUID
    var clientId:     UUID
    var rawText:      String        // what the user said
    var mealName:     String        // parsed: "Scrambled Eggs & Oatmeal"
    var mealType:     String        // Breakfast / Lunch / Dinner / Snack
    var calories:     Int
    var proteinG:     Double
    var carbsG:       Double
    var fatG:         Double
    var foods:        [ParsedFood]  // individual items
    var loggedAt:     Date?
    var createdAt:    Date?

    enum CodingKeys: String, CodingKey {
        case id, calories, foods
        case clientId  = "client_id"
        case rawText   = "raw_text"
        case mealName  = "meal_name"
        case mealType  = "meal_type"
        case proteinG  = "protein_g"
        case carbsG    = "carbs_g"
        case fatG      = "fat_g"
        case loggedAt  = "logged_at"
        case createdAt = "created_at"
    }
}

struct ParsedFood: Codable, Identifiable {
    var id:       UUID = UUID()
    var name:     String
    var quantity:  String   // "2 large" / "1 cup"
    var calories: Int
    var proteinG: Double
    var carbsG:   Double
    var fatG:     Double
}

// MARK: - Claude Meal Parser

@MainActor
class ClaudeMealParser: ObservableObject {

    struct ParsedMeal: Codable {
        var mealName:  String
        var mealType:  String
        var calories:  Int
        var proteinG:  Double
        var carbsG:    Double
        var fatG:      Double
        var foods:     [ParsedFood]
        var confidence: String   // "high" / "medium" / "estimated"
    }

    func parse(speechText: String) async throws -> ParsedMeal {
        let prompt = """
        You are a nutrition expert. The user described a meal by speaking:
        "\(speechText)"

        Parse this into structured nutrition data. Return ONLY valid JSON with no markdown, no explanation, no backticks.

        Use this exact schema:
        {
          "mealName": "Short descriptive name for the meal",
          "mealType": "Breakfast" | "Lunch" | "Dinner" | "Snack",
          "calories": integer,
          "proteinG": number,
          "carbsG": number,
          "fatG": number,
          "confidence": "high" | "medium" | "estimated",
          "foods": [
            {
              "id": "unique-uuid-string",
              "name": "food name",
              "quantity": "amount and unit",
              "calories": integer,
              "proteinG": number,
              "carbsG": number,
              "fatG": number
            }
          ]
        }

        Rules:
        - Use standard USDA nutrition values where known
        - If quantity is unclear, assume a standard serving
        - mealType should infer from context (e.g. "morning coffee" = Breakfast)
        - If completely unable to parse, return calories: 0 and confidence: "estimated"
        - Always return valid JSON — never return text or explanations
        """

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1000,
            "messages": [["role": "user", "content": prompt]]
        ]

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response  = try JSONDecoder().decode(AnthropicResponse.self, from: data)

        guard let content = response.content.first?.text else {
            throw MealParseError.noResponse
        }

        // Strip any accidental markdown fences
        let clean = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let jsonData = clean.data(using: .utf8) ?? Data()
        return try JSONDecoder().decode(ParsedMeal.self, from: jsonData)
    }

    struct AnthropicResponse: Codable {
        struct Content: Codable { var text: String }
        var content: [Content]
    }

    enum MealParseError: LocalizedError {
        case noResponse
        var errorDescription: String? { "Could not parse meal from Claude response." }
    }
}

// MARK: - Meal Log Store

@MainActor
class MealLogStore: ObservableObject {
    static let shared = MealLogStore()
    @Published var logs: [MealLogEntry] = []
    private init() {}

    func fetchForClient(_ clientId: UUID) async throws {
        let today = Calendar.current.startOfDay(for: Date())
        logs = try await supabase
            .from("meal_logs")
            .select()
            .eq("client_id", value: clientId)
            .gte("logged_at", value: today.ISO8601Format())
            .order("logged_at", ascending: false)
            .execute()
            .value
    }

    func save(_ entry: MealLogEntry) async throws {
        try await supabase.from("meal_logs").insert(entry).execute()
        logs.insert(entry, at: 0)
    }

    func delete(_ id: UUID) async throws {
        try await supabase.from("meal_logs").delete().eq("id", value: id).execute()
        logs.removeAll { $0.id == id }
    }

    var todayCalories: Int { logs.reduce(0) { $0 + $1.calories } }
    var todayProtein:  Double { logs.reduce(0) { $0 + $1.proteinG } }
    var todayCarbs:    Double { logs.reduce(0) { $0 + $1.carbsG } }
    var todayFat:      Double { logs.reduce(0) { $0 + $1.fatG } }
}

// MARK: - Speech Recognizer

@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcript   = ""
    @Published var isRecording  = false
    @Published var error:  String? = nil

    private var recognizer:     SFSpeechRecognizer?
    private var request:        SFSpeechAudioBufferRecognitionRequest?
    private var task:           SFSpeechRecognitionTask?
    private let audioEngine     = AVAudioEngine()

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        let micStatus = await AVAudioApplication.requestRecordPermission()
        return speechStatus == .authorized && micStatus
    }

    func startRecording() {
        transcript  = ""
        error       = nil
        isRecording = true

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format    = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buf, _ in
            self?.request?.append(buf)
        }

        audioEngine.prepare()
        try? audioEngine.start()

        task = recognizer?.recognitionTask(with: request) { [weak self] result, err in
            guard let self else { return }
            if let result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            if err != nil || result?.isFinal == true {
                Task { @MainActor in self.stopRecording() }
            }
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request    = nil
        task       = nil
        isRecording = false
    }
}

// MARK: - Voice Meal Logger View

struct VoiceMealLoggerView: View {
    let clientId: String
    @Environment(\.dismiss) var dismiss

    @StateObject private var speech  = SpeechRecognizer()
    @StateObject private var parser  = ClaudeMealParser()
    @StateObject private var store   = MealLogStore.shared

    @State private var phase: LogPhase = .idle
    @State private var parsedMeal: ClaudeMealParser.ParsedMeal? = nil
    @State private var errorMessage  = ""
    @State private var showError     = false
    @State private var hasPermission = false

    enum LogPhase {
        case idle, recording, parsing, review, saved
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        switch phase {
                        case .idle:     idleView
                        case .recording: recordingView
                        case .parsing:  parsingView
                        case .review:   reviewView
                        case .saved:    savedView
                        }
                    }
                    .padding(20)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            hasPermission = await speech.requestPermissions()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").fontWeight(.semibold)
                    Text("Cancel")
                }
                .foregroundColor(.tmGold)
            }
            Spacer()
            Text("Voice Meal Log").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
            Spacer()
            // balance
            Color.clear.frame(width: 60)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(Color.black)
    }

    // MARK: Idle

    private var idleView: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 40)

            VStack(spacing: 16) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 72)).foregroundColor(.tmGold.opacity(0.8))
                Text("What did you eat?")
                    .font(.system(size: 28, weight: .black)).foregroundColor(.white)
                Text("Tap the mic and describe your meal naturally.\nClaude AI will figure out the rest.")
                    .font(.subheadline).foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

            // Example prompts
            VStack(spacing: 10) {
                exampleChip("\"I had two scrambled eggs and oatmeal for breakfast\"")
                exampleChip("\"Grilled chicken salad with olive oil dressing for lunch\"")
                exampleChip("\"Protein shake with banana and peanut butter\"")
            }

            Spacer()

            micButton

            if !hasPermission {
                Text("Microphone & speech recognition permissions required.\nPlease enable in Settings.")
                    .font(.caption).foregroundColor(.red.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func exampleChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13)).foregroundColor(.white.opacity(0.5)).italic()
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.05)))
            .frame(maxWidth: .infinity)
    }

    // MARK: Recording

    private var recordingView: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 40)

            // Animated mic indicator
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.tmGold.opacity(0.3 - Double(i) * 0.08), lineWidth: 2)
                        .frame(width: CGFloat(120 + i * 40), height: CGFloat(120 + i * 40))
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 1.2).repeatForever().delay(Double(i) * 0.3), value: speech.isRecording)
                }
                Circle().fill(Color.red).frame(width: 100, height: 100)
                    .overlay(Image(systemName: "mic.fill").font(.system(size: 40)).foregroundColor(.white))
            }

            Text("Listening...")
                .font(.system(size: 22, weight: .bold)).foregroundColor(.white)

            // Live transcript
            if !speech.transcript.isEmpty {
                Text(speech.transcript)
                    .font(.system(size: 16)).foregroundColor(.tmGold)
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
                    .animation(.easeInOut, value: speech.transcript)
            } else {
                Text("Start speaking...")
                    .font(.system(size: 16)).foregroundColor(.white.opacity(0.3)).italic()
            }

            Spacer()

            Button(action: stopAndParse) {
                HStack(spacing: 10) {
                    Image(systemName: "stop.circle.fill").font(.title2)
                    Text("DONE").font(.system(size: 16, weight: .heavy)).tracking(0.5)
                }
                .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 28).fill(Color.tmGold))
            }
        }
    }

    // MARK: Parsing

    private var parsingView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)
            ProgressView().tint(.tmGold).scaleEffect(1.6)
            Text("Analyzing your meal...").font(.title3).fontWeight(.semibold).foregroundColor(.white)
            Text("Claude AI is calculating nutrition info").font(.subheadline).foregroundColor(.white.opacity(0.4))

            if !speech.transcript.isEmpty {
                Text("\"\(speech.transcript)\"")
                    .font(.system(size: 15)).foregroundColor(.tmGold).italic()
                    .multilineTextAlignment(.center).padding(.horizontal, 20)
            }
            Spacer()
        }
    }

    // MARK: Review

    private var reviewView: some View {
        VStack(spacing: 20) {
            guard let meal = parsedMeal else { return AnyView(EmptyView()) }
            return AnyView(
                VStack(spacing: 20) {
                    // Header card
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(meal.mealName)
                                    .font(.system(size: 20, weight: .black)).foregroundColor(.white)
                                Text(meal.mealType)
                                    .font(.subheadline).foregroundColor(.tmGold)
                            }
                            Spacer()
                            confidenceBadge(meal.confidence)
                        }

                        // Original transcript
                        Text("\"\(speech.transcript)\"")
                            .font(.caption).foregroundColor(.white.opacity(0.4)).italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06)))

                    // Macro summary
                    macroRow(calories: meal.calories, protein: meal.proteinG, carbs: meal.carbsG, fat: meal.fatG)

                    // Individual foods
                    if !meal.foods.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("BREAKDOWN").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                            ForEach(meal.foods) { food in
                                foodRow(food)
                            }
                        }
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button(action: saveMeal) {
                            Text("LOG THIS MEAL")
                                .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                                .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 54)
                                .background(RoundedRectangle(cornerRadius: 27).fill(Color.tmGold))
                                .shadow(color: .tmGold.opacity(0.4), radius: 10)
                        }
                        Button(action: retryRecording) {
                            Text("Try Again")
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
            )
        }
    }

    // MARK: Saved

    private var savedView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80)).foregroundColor(.green)
            Text("Meal Logged!").font(.system(size: 28, weight: .black)).foregroundColor(.white)
            if let meal = parsedMeal {
                Text("\(meal.mealName) — \(meal.calories) calories")
                    .font(.subheadline).foregroundColor(.tmGold)
            }
            Spacer()
            VStack(spacing: 12) {
                Button(action: logAnother) {
                    Text("LOG ANOTHER MEAL")
                        .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                        .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 27).fill(Color.tmGold))
                }
                Button(action: { dismiss() }) {
                    Text("Done").font(.system(size: 14, weight: .semibold)).foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }

    // MARK: Sub-views

    private var micButton: some View {
        Button(action: startRecording) {
            ZStack {
                Circle().fill(hasPermission ? Color.tmGold : Color.gray.opacity(0.4))
                    .frame(width: 100, height: 100)
                    .shadow(color: hasPermission ? Color.tmGold.opacity(0.5) : .clear, radius: 20)
                Image(systemName: "mic.fill").font(.system(size: 42)).foregroundColor(.black)
            }
        }
        .disabled(!hasPermission)
    }

    private func confidenceBadge(_ confidence: String) -> some View {
        let color: Color = confidence == "high" ? .green : confidence == "medium" ? .tmGold : .orange
        let label = confidence == "high" ? "High Confidence" : confidence == "medium" ? "Medium" : "Estimated"
        return Text(label)
            .font(.system(size: 10, weight: .bold)).foregroundColor(.black)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Capsule().fill(color))
    }

    private func macroRow(calories: Int, protein: Double, carbs: Double, fat: Double) -> some View {
        HStack(spacing: 0) {
            macroCell("\(calories)", "cal", .tmGold)
            Divider().background(Color.white.opacity(0.1)).frame(height: 40)
            macroCell(String(format: "%.0fg", protein), "protein", .red)
            Divider().background(Color.white.opacity(0.1)).frame(height: 40)
            macroCell(String(format: "%.0fg", carbs), "carbs", .blue)
            Divider().background(Color.white.opacity(0.1)).frame(height: 40)
            macroCell(String(format: "%.0fg", fat), "fat", .yellow)
        }
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
    }

    private func macroCell(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 20, weight: .black)).foregroundColor(color)
            Text(label).font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private func foodRow(_ food: ParsedFood) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(food.quantity).font(.caption).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(food.calories) cal").font(.system(size: 13, weight: .bold)).foregroundColor(.tmGold)
                Text(String(format: "P:%.0fg C:%.0fg F:%.0fg", food.proteinG, food.carbsG, food.fatG))
                    .font(.caption2).foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
    }

    // MARK: Actions

    private func startRecording() {
        phase = .recording
        speech.startRecording()
    }

    private func stopAndParse() {
        speech.stopRecording()
        guard !speech.transcript.isEmpty else {
            phase = .idle
            return
        }
        phase = .parsing
        Task {
            do {
                parsedMeal = try await parser.parse(speechText: speech.transcript)
                phase = .review
            } catch {
                errorMessage = "Could not analyze your meal. Please try again."
                showError    = true
                phase        = .idle
            }
        }
    }

    private func saveMeal() {
        guard let meal = parsedMeal, let clientUUID = UUID(uuidString: clientId) else { return }
        let entry = MealLogEntry(
            id: UUID(), clientId: clientUUID,
            rawText: speech.transcript,
            mealName: meal.mealName, mealType: meal.mealType,
            calories: meal.calories,
            proteinG: meal.proteinG, carbsG: meal.carbsG, fatG: meal.fatG,
            foods: meal.foods,
            loggedAt: Date(), createdAt: Date()
        )
        Task {
            do {
                try await store.save(entry)
                phase = .saved
            } catch {
                errorMessage = "Failed to save meal. Please try again."
                showError    = true
            }
        }
    }

    private func retryRecording() {
        parsedMeal = nil
        speech.transcript = ""
        phase = .idle
    }

    private func logAnother() {
        parsedMeal = nil
        speech.transcript = ""
        phase = .idle
    }
}

// MARK: - Daily Nutrition Summary (add to client hub)

struct DailyNutritionSummaryView: View {
    let clientId: String
    @ObservedObject private var store = MealLogStore.shared
    @State private var showingVoiceLog = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "fork.knife").font(.caption).foregroundColor(.tmGold)
                    Text("TODAY'S NUTRITION")
                        .font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                }
                Spacer()
                Button(action: { showingVoiceLog = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "mic.fill").font(.caption)
                        Text("Log Meal")
                    }
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(.black)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Capsule().fill(Color.tmGold))
                }
            }

            // Macro totals
            HStack(spacing: 0) {
                macroCell("\(store.todayCalories)", "cal", .tmGold)
                Divider().background(Color.white.opacity(0.08)).frame(height: 36)
                macroCell(String(format: "%.0fg", store.todayProtein), "protein", .red)
                Divider().background(Color.white.opacity(0.08)).frame(height: 36)
                macroCell(String(format: "%.0fg", store.todayCarbs), "carbs", .blue)
                Divider().background(Color.white.opacity(0.08)).frame(height: 36)
                macroCell(String(format: "%.0fg", store.todayFat), "fat", .yellow)
            }
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))

            // Today's meals list
            if store.logs.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "mic.circle").font(.title2).foregroundColor(.tmGold.opacity(0.4))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No meals logged today").font(.subheadline).foregroundColor(.white.opacity(0.5))
                        Text("Tap Log Meal and just say what you ate").font(.caption).foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
            } else {
                ForEach(store.logs.prefix(4)) { log in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.mealName).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                            Text(log.mealType).font(.caption).foregroundColor(.tmGold)
                        }
                        Spacer()
                        Text("\(log.calories) cal").font(.system(size: 13, weight: .bold)).foregroundColor(.tmGold)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                }
            }
        }
        .onAppear {
            if let uuid = UUID(uuidString: clientId) {
                Task { try? await store.fetchForClient(uuid) }
            }
        }
        .sheet(isPresented: $showingVoiceLog) {
            VoiceMealLoggerView(clientId: clientId)
        }
    }

    private func macroCell(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 16, weight: .black)).foregroundColor(color)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }
}
