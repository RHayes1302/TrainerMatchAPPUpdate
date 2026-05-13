//
//  TrainerScheduleStore.swift
//  TrainerMatch
//
//  Full scheduling system — events, overbooking prevention, calendar view
//

//
//  TrainerScheduleStore.swift
//  TrainerMatch
//
//  Full scheduling system — events, overbooking prevention, calendar view
//

import SwiftUI

// MARK: - Model

struct TrainerEvent: Identifiable, Codable {
    let id: String
    var trainerId: String
    var title: String
    var eventType: EventType
    var clientId: String?
    var clientName: String?
    var startDate: Date
    var endDate: Date
    var notes: String?
    var isRecurring: Bool
    var recurringDays: [Int]   // 0=Sun … 6=Sat
    var color: EventColor

    enum EventType: String, Codable, CaseIterable {
        case session       = "Training Session"
        case progressCheck = "Progress Check"
        case consultation  = "Consultation"
        case meeting       = "Meeting"
        case personal      = "Personal / Block"
        case other         = "Other"
    }

    enum EventColor: String, Codable, CaseIterable {
        case gold   = "Gold"
        case blue   = "Blue"
        case green  = "Green"
        case red    = "Red"
        case purple = "Purple"
        case orange = "Orange"

        var color: Color {
            switch self {
            case .gold:   return .tmGold
            case .blue:   return .blue
            case .green:  return .green
            case .red:    return Color(red: 0.9, green: 0.2, blue: 0.2)
            case .purple: return .purple
            case .orange: return .orange
            }
        }
    }

    var duration: TimeInterval { endDate.timeIntervalSince(startDate) }

    var formattedTime: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return "\(f.string(from: startDate)) – \(f.string(from: endDate))"
    }

    var typeIcon: String {
        switch eventType {
        case .session:       return "figure.strengthtraining.traditional"
        case .progressCheck: return "chart.line.uptrend.xyaxis"
        case .consultation:  return "person.fill.questionmark"
        case .meeting:       return "person.2.fill"
        case .personal:      return "lock.fill"
        case .other:         return "calendar"
        }
    }

    init(trainerId: String, title: String, eventType: EventType,
         clientId: String? = nil, clientName: String? = nil,
         startDate: Date, endDate: Date, notes: String? = nil,
         isRecurring: Bool = false, recurringDays: [Int] = [],
         color: EventColor = .gold) {
        self.id           = UUID().uuidString
        self.trainerId    = trainerId
        self.title        = title
        self.eventType    = eventType
        self.clientId     = clientId
        self.clientName   = clientName
        self.startDate    = startDate
        self.endDate      = endDate
        self.notes        = notes
        self.isRecurring  = isRecurring
        self.recurringDays = recurringDays
        self.color        = color
    }
}

// MARK: - Store

class TrainerScheduleStore: ObservableObject {
    static let shared = TrainerScheduleStore()
    @Published var events: [TrainerEvent] = []

    private let fm = FileManager.default
    private var storeURL: URL {
        fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("trainerSchedule.json")
    }

    private init() { load() }

    // Events for a trainer on a specific day
    func events(forTrainer trainerId: String, on date: Date) -> [TrainerEvent] {
        let cal = Calendar.current
        return events
            .filter { $0.trainerId == trainerId }
            .filter { event in
                if cal.isDate(event.startDate, inSameDayAs: date) { return true }
                if event.isRecurring {
                    let weekday = cal.component(.weekday, from: date) - 1
                    return event.recurringDays.contains(weekday)
                }
                return false
            }
            .sorted { $0.startDate < $1.startDate }
    }

    // Events for a trainer in a date range
    func events(forTrainer trainerId: String, from start: Date, to end: Date) -> [TrainerEvent] {
        events.filter {
            $0.trainerId == trainerId &&
            $0.startDate >= start && $0.startDate <= end
        }.sorted { $0.startDate < $1.startDate }
    }

    // Check for conflicts (overbooking)
    func conflicts(for event: TrainerEvent, excluding id: String? = nil) -> [TrainerEvent] {
        events.filter {
            $0.id != (id ?? "") &&
            $0.trainerId == event.trainerId &&
            $0.startDate < event.endDate &&
            $0.endDate > event.startDate
        }
    }

    func addEvent(_ event: TrainerEvent) { events.append(event); save() }

    func updateEvent(_ event: TrainerEvent) {
        if let i = events.firstIndex(where: { $0.id == event.id }) {
            events[i] = event; save()
        }
    }

    func deleteEvent(_ event: TrainerEvent) {
        events.removeAll { $0.id == event.id }; save()
    }

    // Days in a month that have events
    func daysWithEvents(forTrainer trainerId: String, in month: Date) -> Set<Int> {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: month)
        guard let start = cal.date(from: comps),
              let end = cal.date(byAdding: .month, value: 1, to: start) else { return [] }
        let monthEvents = events(forTrainer: trainerId, from: start, to: end)
        return Set(monthEvents.map { cal.component(.day, from: $0.startDate) })
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        try? data.write(to: storeURL)
    }

    private func load() {
        guard fm.fileExists(atPath: storeURL.path),
              let data = try? Data(contentsOf: storeURL),
              let saved = try? JSONDecoder().decode([TrainerEvent].self, from: data)
        else { return }
        events = saved
    }
}

// MARK: - Main Schedule View (replaces ScheduleSection placeholder)

struct TrainerScheduleView: View {
    let trainerId: String
    @ObservedObject private var scheduleStore = TrainerScheduleStore.shared
    @ObservedObject private var connectionStore = TrainerConnectionStore.shared
    @ObservedObject private var requestStore = AppointmentRequestStore.shared
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @State private var showingAddEvent = false
    @State private var showingRequests = false
    @State private var selectedEvent: TrainerEvent?

    private var pendingRequestCount: Int {
        requestStore.pendingRequests(forTrainer: trainerId).count
    }

    private var todayEvents: [TrainerEvent] {
        scheduleStore.events(forTrainer: trainerId, on: selectedDate)
    }

    private var daysWithDots: Set<Int> {
        scheduleStore.daysWithEvents(forTrainer: trainerId, in: displayedMonth)
    }

    var body: some View {
        VStack(spacing: 0) {
            if pendingRequestCount > 0 {
                Button(action: { showingRequests = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.badge.fill").foregroundColor(.black)
                        Text("\(pendingRequestCount) session request\(pendingRequestCount == 1 ? "" : "s") pending")
                            .font(.system(size: 13, weight: .bold)).foregroundColor(.black)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.black.opacity(0.6))
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(Color.tmGold)
                }
            }
            calendarHeader
            calendarGrid
            Divider().background(Color.white.opacity(0.1))
            dayEventsSection
        }
        .sheet(isPresented: $showingAddEvent) {
            NavigationView {
                AddEditEventView(
                    trainerId: trainerId,
                    prefillDate: selectedDate,
                    connections: connectionStore.activeClients(forTrainer: trainerId)
                )
            }
            .tint(.tmGold)
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(item: $selectedEvent) { event in
            NavigationView {
                AddEditEventView(
                    trainerId: trainerId,
                    existingEvent: event,
                    connections: connectionStore.activeClients(forTrainer: trainerId)
                )
            }
            .tint(.tmGold)
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(isPresented: $showingRequests) {
            NavigationView {
                TrainerIncomingRequestsView(trainerId: trainerId)
            }
            .tint(.tmGold)
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    // MARK: Calendar header (month nav + add button)
    private var calendarHeader: some View {
        HStack {
            Button(action: { shiftMonth(-1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.tmGold)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.07)))
            }
            Spacer()
            Text(monthTitle(displayedMonth))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button(action: { shiftMonth(1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.tmGold)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.07)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: Calendar grid
    private var calendarGrid: some View {
        VStack(spacing: 4) {
            // Day labels
            HStack(spacing: 0) {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)

            // Weeks
            let weeks = calendarWeeks(for: displayedMonth)
            ForEach(weeks.indices, id: \.self) { wi in
                HStack(spacing: 0) {
                    ForEach(weeks[wi], id: \.self) { date in
                        calendarCell(date)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func calendarCell(_ date: Date?) -> some View {
        if let date = date {
            let cal = Calendar.current
            let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
            let isToday    = cal.isDateInToday(date)
            let day        = cal.component(.day, from: date)
            let hasEvent   = daysWithDots.contains(day) && cal.isDate(date, equalTo: displayedMonth, toGranularity: .month)

            Button(action: { selectedDate = date }) {
                VStack(spacing: 3) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.tmGold : (isToday ? Color.tmGold.opacity(0.2) : Color.clear))
                            .frame(width: 34, height: 34)
                        Text("\(day)")
                            .font(.system(size: 14, weight: isSelected || isToday ? .bold : .regular))
                            .foregroundColor(isSelected ? .black : (isToday ? .tmGold : .white))
                    }
                    Circle()
                        .fill(hasEvent ? (isSelected ? Color.black : Color.tmGold) : Color.clear)
                        .frame(width: 5, height: 5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
            }
        } else {
            Spacer().frame(maxWidth: .infinity)
        }
    }

    // MARK: Events for selected day
    private var dayEventsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(dayTitle(selectedDate))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Button(action: { showingAddEvent = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Capsule().fill(Color.tmGold))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if todayEvents.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.15))
                    Text("No events. Tap Add to schedule something.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(todayEvents) { event in
                            EventRow(event: event)
                                .onTapGesture { selectedEvent = event }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color.white.opacity(0.02))
    }

    // MARK: Helpers
    private func shiftMonth(_ value: Int) {
        displayedMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }

    private func monthTitle(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: date)
    }

    private func dayTitle(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"; return f.string(from: date).uppercased()
    }

    private func calendarWeeks(for month: Date) -> [[Date?]] {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: month)
        guard let firstDay = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: firstDay) else { return [] }
        let firstWeekday = cal.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for d in range {
            comps.day = d
            days.append(cal.date(from: comps))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<$0+7]) }
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: TrainerEvent

    var body: some View {
        HStack(spacing: 14) {
            // Color bar
            RoundedRectangle(cornerRadius: 3)
                .fill(event.color.color)
                .frame(width: 4)
                .frame(height: 56)

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(event.color.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: event.typeIcon)
                    .font(.system(size: 16))
                    .foregroundColor(event.color.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(event.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if event.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                Text(event.formattedTime)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                if let clientName = event.clientName {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill").font(.caption2)
                        Text(clientName).font(.caption)
                    }
                    .foregroundColor(.tmGold.opacity(0.8))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.25))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14)
            .fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(event.color.color.opacity(0.2), lineWidth: 1)))
    }
}

// MARK: - Add / Edit Event View

struct AddEditEventView: View {
    let trainerId: String
    var existingEvent: TrainerEvent? = nil
    var prefillDate: Date? = nil
    let connections: [TrainerClientConnection]
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var scheduleStore = TrainerScheduleStore.shared

    @State private var title = ""
    @State private var eventType: TrainerEvent.EventType = .session
    @State private var selectedClientId: String? = nil
    @State private var selectedClientName: String? = nil
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var recurringDays: Set<Int> = []
    @State private var selectedColor: TrainerEvent.EventColor = .gold
    @State private var showingConflict = false
    @State private var conflictingEvents: [TrainerEvent] = []

    var isEditing: Bool { existingEvent != nil }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    titleField
                    typeAndColorRow
                    clientPicker
                    dateTimeSection
                    recurringSection
                    notesField
                    if isEditing { deleteButton }
                    saveButton
                }
                .padding(20)
            }
        }
        .navigationTitle(isEditing ? "Edit Event" : "New Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .onAppear { prefill() }
        .alert("Schedule Conflict", isPresented: $showingConflict) {
            Button("Go Back", role: .cancel) {}
            Button("Save Anyway") { saveEvent() }
        } message: {
            Text("This overlaps with: \(conflictingEvents.map(\.title).joined(separator: ", ")). Save anyway?")
        }
    }

    // MARK: Sub-views
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            formLabel("TITLE")
            TextField("e.g. Session with Marcus", text: $title)
                .foregroundColor(.white)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }

    private var typeAndColorRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                formLabel("TYPE")
                Menu {
                    ForEach(TrainerEvent.EventType.allCases, id: \.self) { t in
                        Button(t.rawValue) { eventType = t }
                    }
                } label: {
                    HStack {
                        Image(systemName: iconFor(eventType)).foregroundColor(.tmGold)
                        Text(eventType.rawValue)
                            .font(.system(size: 13)).foregroundColor(.white).lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.down").font(.caption).foregroundColor(.gray)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                formLabel("COLOR")
                HStack(spacing: 8) {
                    ForEach(TrainerEvent.EventColor.allCases, id: \.self) { c in
                        Button(action: { selectedColor = c }) {
                            Circle()
                                .fill(c.color)
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.white, lineWidth: selectedColor == c ? 2 : 0))
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            }
        }
    }

    private var clientPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            formLabel("CLIENT (OPTIONAL)")
            if connections.isEmpty {
                Text("No connected clients")
                    .font(.subheadline).foregroundColor(.white.opacity(0.3))
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
            } else {
                Menu {
                    Button("None") { selectedClientId = nil; selectedClientName = nil }
                    ForEach(connections) { conn in
                        Button(conn.clientName) {
                            selectedClientId = conn.clientId
                            selectedClientName = conn.clientName
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "person.fill").foregroundColor(.tmGold)
                        Text(selectedClientName ?? "Select Client")
                            .font(.subheadline)
                            .foregroundColor(selectedClientName == nil ? .gray : .white)
                        Spacer()
                        Image(systemName: "chevron.down").font(.caption).foregroundColor(.gray)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
            }
        }
    }

    private var dateTimeSection: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                formLabel("START")
                DatePicker("", selection: $startDate)
                    .datePickerStyle(.compact)
                    .colorScheme(.dark)
                    .tint(.tmGold)
                    .labelsHidden()
                    .onChange(of: startDate) { _, newVal in
                        if endDate <= newVal {
                            endDate = newVal.addingTimeInterval(3600)
                        }
                    }
            }
            VStack(alignment: .leading, spacing: 6) {
                formLabel("END")
                DatePicker("", selection: $endDate, in: startDate...)
                    .datePickerStyle(.compact)
                    .colorScheme(.dark)
                    .tint(.tmGold)
                    .labelsHidden()
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
    }

    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $isRecurring) {
                HStack(spacing: 8) {
                    Image(systemName: "repeat").foregroundColor(.tmGold)
                    Text("Recurring").foregroundColor(.white).fontWeight(.semibold)
                }
            }
            .tint(.tmGold)

            if isRecurring {
                HStack(spacing: 8) {
                    ForEach(Array(zip(["S","M","T","W","T","F","S"], 0...6)), id: \.1) { label, idx in
                        Button(action: {
                            if recurringDays.contains(idx) { recurringDays.remove(idx) }
                            else { recurringDays.insert(idx) }
                        }) {
                            Text(label)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(recurringDays.contains(idx) ? .black : .white.opacity(0.5))
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(recurringDays.contains(idx) ? Color.tmGold : Color.white.opacity(0.07)))
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            formLabel("NOTES (OPTIONAL)")
            TextField("Any notes about this event...", text: $notes, axis: .vertical)
                .foregroundColor(.white)
                .lineLimit(3...5)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }

    private var saveButton: some View {
        Button(action: checkAndSave) {
            Text(isEditing ? "SAVE CHANGES" : "ADD TO SCHEDULE")
                .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(RoundedRectangle(cornerRadius: 27)
                    .fill(title.isEmpty ? Color.tmGold.opacity(0.3) : Color.tmGold))
        }
        .disabled(title.isEmpty)
    }

    private var deleteButton: some View {
        Button(action: {
            if let e = existingEvent { scheduleStore.deleteEvent(e); dismiss() }
        }) {
            Text("Delete Event")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.red.opacity(0.8))
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 27)
                    .fill(Color.red.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 27)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)))
        }
    }

    // MARK: Helpers
    private func checkAndSave() {
        let draft = buildEvent()
        let conflicts = scheduleStore.conflicts(for: draft, excluding: existingEvent?.id)
        if conflicts.isEmpty { saveEvent() }
        else { conflictingEvents = conflicts; showingConflict = true }
    }

    private func saveEvent() {
        let event = buildEvent()
        if isEditing { scheduleStore.updateEvent(event) }
        else { scheduleStore.addEvent(event) }
        dismiss()
    }

    private func buildEvent() -> TrainerEvent {
        TrainerEvent(
            trainerId: trainerId,
            title: title,
            eventType: eventType,
            clientId: selectedClientId,
            clientName: selectedClientName,
            startDate: startDate,
            endDate: endDate,
            notes: notes.isEmpty ? nil : notes,
            isRecurring: isRecurring,
            recurringDays: Array(recurringDays),
            color: selectedColor
        )
    }

    private func prefill() {
        if let date = prefillDate, existingEvent == nil {
            startDate = date
            endDate = date.addingTimeInterval(3600)
        }
        guard let e = existingEvent else { return }
        title = e.title
        eventType = e.eventType
        selectedClientId = e.clientId
        selectedClientName = e.clientName
        startDate = e.startDate
        endDate = e.endDate
        notes = e.notes ?? ""
        isRecurring = e.isRecurring
        recurringDays = Set(e.recurringDays)
        selectedColor = e.color
    }

    private func formLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold)).tracking(1.2)
            .foregroundColor(.tmGold)
    }

    private func iconFor(_ type: TrainerEvent.EventType) -> String {
        switch type {
        case .session:       return "figure.strengthtraining.traditional"
        case .progressCheck: return "chart.line.uptrend.xyaxis"
        case .consultation:  return "person.fill.questionmark"
        case .meeting:       return "person.2.fill"
        case .personal:      return "lock.fill"
        case .other:         return "calendar"
        }
    }
}
