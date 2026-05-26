//
//  AddClientView.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/10/26.
//

import SwiftUI

// MARK: - Add Client View
struct AddClientView: View {
    @ObservedObject var trainerVM: TrainerViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var currentWeight = ""
    @State private var goalWeight = ""
    @State private var height = ""
    @State private var notes = ""
    @State private var selectedGoals: Set<FitnessGoal> = []
    @State private var selectedServiceType: ServiceType = .inPerson
    @State private var foundVia = "Nearby Trainers"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone Number (Optional)", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Body Metrics")) {
                    HStack {
                        TextField("Current Weight", text: $currentWeight)
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        TextField("Goal Weight", text: $goalWeight)
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        TextField("Height", text: $height)
                            .keyboardType(.decimalPad)
                        Text("cm")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Fitness Goals")) {
                    ForEach(FitnessGoal.allCases, id: \.self) { goal in
                        Button(action: {
                            if selectedGoals.contains(goal) {
                                selectedGoals.remove(goal)
                            } else {
                                selectedGoals.insert(goal)
                            }
                        }) {
                            HStack {
                                Text(goal.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedGoals.contains(goal) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Training Preferences")) {
                    Picker("Service Type", selection: $selectedServiceType) {
                        ForEach(ServiceType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Picker("How did they find you?", selection: $foundVia) {
                        Text("Nearby Trainers").tag("Nearby Trainers")
                        Text("Referral").tag("Referral")
                        Text("Social Media").tag("Social Media")
                        Text("Other").tag("Other")
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveClient()
                    }
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
    }
    
    private func saveClient() {
        let newClient = Client(
            name: name,
            email: email,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            dateJoined: Date(),
            trainerId: trainerVM.currentTrainerId,
            currentWeight: Double(currentWeight),
            goalWeight: Double(goalWeight),
            height: Double(height),
            fitnessGoals: Array(selectedGoals),
            preferredServiceType: selectedServiceType,
            foundVia: foundVia,
            trainerNotes: notes.isEmpty ? nil : notes
        )
        
        trainerVM.addClient(newClient)
        dismiss()
    }
}

// MARK: - Add Workout View
struct AddWorkoutView: View {
    let client: Client
    @ObservedObject var trainerVM: TrainerViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var workoutName = ""
    @State private var workoutDescription = ""
    @State private var selectedDifficulty: WorkoutDifficulty = .intermediate
    @State private var estimatedDuration = ""
    @State private var dueDate = Date().addingTimeInterval(7*24*60*60)
    @State private var exercises: [Exercise] = []
    @State private var showingAddExercise = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Workout Details")) {
                    TextField("Workout Name", text: $workoutName)
                    TextField("Description (Optional)", text: $workoutDescription)
                    
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        ForEach(WorkoutDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.rawValue).tag(difficulty)
                        }
                    }
                    
                    HStack {
                        TextField("Estimated Duration", text: $estimatedDuration)
                            .keyboardType(.numberPad)
                        Text("minutes")
                            .foregroundColor(.gray)
                    }
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
                
                Section(header: HStack {
                    Text("Exercises")
                    Spacer()
                    Button(action: { showingAddExercise = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }) {
                    if exercises.isEmpty {
                        Text("No exercises added yet")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(exercises) { exercise in
                            ExerciseRowView(exercise: exercise)
                        }
                        .onDelete(perform: deleteExercise)
                    }
                }
            }
            .navigationTitle("Assign Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Assign") {
                        assignWorkout()
                    }
                    .disabled(workoutName.isEmpty || exercises.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView(exercises: $exercises)
            }
        }
    }
    
    private func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }
    
    private func assignWorkout() {
        let newWorkout = Workout(
            name: workoutName,
            description: workoutDescription.isEmpty ? nil : workoutDescription,
            exercises: exercises,
            assignedDate: Date(),
            dueDate: dueDate,
            clientId: client.id,
            trainerId: trainerVM.currentTrainerId,
            difficulty: selectedDifficulty,
            estimatedDuration: Int(estimatedDuration)
        )
        
        trainerVM.assignWorkout(newWorkout, to: client)
        dismiss()
    }
}

// MARK: - Exercise Row View
struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            
            HStack {
                if let sets = exercise.sets, let reps = exercise.reps {
                    Text("\(sets) sets × \(reps) reps")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else if let duration = exercise.duration {
                    Text("\(duration / 60) min")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text("•")
                    .foregroundColor(.gray)
                
                Text(exercise.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Add Exercise View
struct AddExerciseView: View {
    @Binding var exercises: [Exercise]
    @Environment(\.dismiss) var dismiss
    
    @State private var exerciseName = ""
    @State private var selectedCategory: ExerciseCategory = .strength
    @State private var exerciseDescription = ""
    @State private var sets = ""
    @State private var reps = ""
    @State private var duration = ""
    @State private var restTime = ""
    @State private var exerciseType: ExerciseType = .setsAndReps
    
    enum ExerciseType {
        case setsAndReps
        case duration
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Name", text: $exerciseName)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    TextField("Description (Optional)", text: $exerciseDescription)
                }
                
                Section(header: Text("Exercise Configuration")) {
                    Picker("Type", selection: $exerciseType) {
                        Text("Sets & Reps").tag(ExerciseType.setsAndReps)
                        Text("Duration").tag(ExerciseType.duration)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if exerciseType == .setsAndReps {
                        TextField("Sets", text: $sets)
                            .keyboardType(.numberPad)
                        
                        TextField("Reps", text: $reps)
                            .keyboardType(.numberPad)
                    } else {
                        HStack {
                            TextField("Duration", text: $duration)
                                .keyboardType(.numberPad)
                            Text("seconds")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        TextField("Rest Time", text: $restTime)
                            .keyboardType(.numberPad)
                        Text("seconds")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addExercise()
                    }
                    .disabled(exerciseName.isEmpty)
                }
            }
        }
    }
    
    private func addExercise() {
        let newExercise = Exercise(
            name: exerciseName,
            category: selectedCategory,
            description: exerciseDescription.isEmpty ? nil : exerciseDescription,
            sets: exerciseType == .setsAndReps ? Int(sets) : nil,
            reps: exerciseType == .setsAndReps ? Int(reps) : nil,
            duration: exerciseType == .duration ? Int(duration) : nil,
            restTime: Int(restTime)
        )
        
        exercises.append(newExercise)
        dismiss()
    }
}

// MARK: - Add Progress Entry View
struct AddProgressEntryView: View {
    let client: Client
    @ObservedObject var trainerVM: TrainerViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var entryDate = Date()
    @State private var weight = ""
    @State private var bodyFat = ""
    @State private var chest = ""
    @State private var waist = ""
    @State private var hips = ""
    @State private var thighs = ""
    @State private var arms = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Entry Details")) {
                    DatePicker("Date", selection: $entryDate, displayedComponents: .date)
                }
                
                Section(header: Text("Body Metrics")) {
                    HStack {
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        TextField("Body Fat %", text: $bodyFat)
                            .keyboardType(.decimalPad)
                        Text("%")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Measurements (Optional)")) {
                    HStack {
                        TextField("Chest", text: $chest)
                            .keyboardType(.decimalPad)
                        Text("cm")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        TextField("Waist", text: $waist)
                            .keyboardType(.decimalPad)
                        Text("cm")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        TextField("Hips", text: $hips)
                            .keyboardType(.decimalPad)
                        Text("cm")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        TextField("Thighs", text: $thighs)
                            .keyboardType(.decimalPad)
                        Text("cm")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        TextField("Arms", text: $arms)
                            .keyboardType(.decimalPad)
                        Text("cm")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Progress Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProgressEntry()
                    }
                }
            }
        }
    }
    
    private func saveProgressEntry() {
        let measurements = BodyMeasurements(
            chest: Double(chest),
            waist: Double(waist),
            hips: Double(hips),
            thighs: Double(thighs),
            arms: Double(arms)
        )
        
        let hasAnyMeasurement = measurements.chest != nil || measurements.waist != nil ||
                                measurements.hips != nil || measurements.thighs != nil ||
                                measurements.arms != nil
        
        let entry = ProgressEntry(
            clientId: client.id,
            date: entryDate,
            weight: Double(weight),
            bodyFat: Double(bodyFat),
            measurements: hasAnyMeasurement ? measurements : nil,
            notes: notes.isEmpty ? nil : notes
        )
        
        trainerVM.addProgressEntry(entry)
        dismiss()
    }
}

// MARK: - Previews
#Preview("Add Client") {
    AddClientView(trainerVM: TrainerViewModel())
}

#Preview("Add Workout") {
    AddWorkoutView(
        client: Client.sampleClients[0],
        trainerVM: TrainerViewModel()
    )
}

#Preview("Add Progress") {
    AddProgressEntryView(
        client: Client.sampleClients[0],
        trainerVM: TrainerViewModel()
    )
}
