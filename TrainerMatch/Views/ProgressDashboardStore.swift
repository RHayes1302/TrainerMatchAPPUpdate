//
//  ProgressDashboardStore.swift
//  TrainerMatch
//

import SwiftUI
import Charts

// MARK: - Weight unit enum (used by chart)
// SBWeightUnit is defined in LegacyModels.swift

// MARK: - Weight Trend Chart

struct WeightTrendChart: View {
    let entries: [SBWeightEntryRow]
    let unit: SBWeightUnit
    var showGoal: Double? = nil
    var accentColor: Color = .tmGold

    private var chartEntries: [SBWeightEntryRow] {
        Array(entries.sorted { ($0.loggedAt ?? .distantPast) < ($1.loggedAt ?? .distantPast) }.suffix(30))
    }

    private func value(_ e: SBWeightEntryRow) -> Double {
        unit == .lbs ? e.weightInLbs : e.weightInKg
    }

    private var minVal: Double { (chartEntries.map { value($0) }.min() ?? 0) - 2 }
    private var maxVal: Double {
        let dataMax = chartEntries.map { value($0) }.max() ?? 0
        return max(dataMax, showGoal ?? 0) + 2
    }

    var body: some View {
        if chartEntries.isEmpty { emptyChart } else { chart }
    }

    private var emptyChart: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32)).foregroundColor(.white.opacity(0.1))
            Text("No weight data yet").font(.caption).foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity).frame(height: 120)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
    }

    private var chart: some View {
        Chart {
            ForEach(chartEntries) { entry in
                LineMark(x: .value("Date", entry.loggedAt ?? Date()), y: .value("Weight", value(entry)))
                    .foregroundStyle(accentColor).lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                AreaMark(
                    x: .value("Date", entry.loggedAt ?? Date()),
                    yStart: .value("Min", minVal), yEnd: .value("Weight", value(entry))
                )
                .foregroundStyle(LinearGradient(
                    colors: [accentColor.opacity(0.25), accentColor.opacity(0)],
                    startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.catmullRom)
                PointMark(x: .value("Date", entry.loggedAt ?? Date()), y: .value("Weight", value(entry)))
                    .foregroundStyle(accentColor).symbolSize(25)
            }
            if let goal = showGoal {
                RuleMark(y: .value("Goal", goal))
                    .foregroundStyle(Color.green.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("Goal").font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green).padding(.horizontal, 4)
                    }
            }
        }
        .chartYScale(domain: minVal...maxVal)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: chartEntries.count > 14 ? 7 : 3)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(Color.white.opacity(0.4))
                AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
            }
        }
        .chartYAxis {
            AxisMarks { val in
                AxisValueLabel {
                    if let v = val.as(Double.self) {
                        Text(String(format: "%.0f", v)).font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
                    }
                }
                AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
            }
        }
        .frame(height: 160).padding(.vertical, 8)
    }
}

// MARK: - Before / After Comparator

struct BeforeAfterComparatorView: View {
    let clientId: String
    @ObservedObject private var checkInStore = SBCheckInStore.shared
    @State private var beforeIdx = 0
    @State private var afterIdx  = 1
    @State private var selectedAngle: PhotoAngle = .front

    enum PhotoAngle: String, CaseIterable {
        case front = "Front"; case rear = "Rear"
        case right = "Right"; case left = "Left"

        func url(from checkIn: CheckInRow) -> URL? {
            let urls = checkIn.photoUrls.compactMap { URL(string: $0) }
            switch self {
            case .front: return urls[safe: 0]
            case .rear:  return urls[safe: 1]
            case .right: return urls[safe: 2]
            case .left:  return urls[safe: 3]
            }
        }
    }

    private var checkIns: [CheckInRow] {
        SBCheckInStore.shared.checkIns(forClient: clientId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PhotoAngle.allCases, id: \.self) { angle in
                        Button(action: { selectedAngle = angle }) {
                            Text(angle.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(selectedAngle == angle ? .black : .white.opacity(0.5))
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(Capsule().fill(selectedAngle == angle ? Color.tmGold : Color.white.opacity(0.08)))
                        }
                    }
                }
            }

            if checkIns.count < 2 {
                VStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 36)).foregroundColor(.white.opacity(0.1))
                    Text("Need at least 2 check-ins for comparison")
                        .font(.caption).foregroundColor(.white.opacity(0.35)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 30)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.03)))
            } else {
                HStack(spacing: 8) {
                    photoCard(checkIn: checkIns[safe: beforeIdx], label: "BEFORE", isLeft: true)
                    VStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 22)).foregroundColor(.tmGold.opacity(0.5))
                    }
                    photoCard(checkIn: checkIns[safe: afterIdx], label: "AFTER", isLeft: false)
                }
                HStack(spacing: 12) {
                    checkInPicker("BEFORE", idx: $beforeIdx, excluding: afterIdx)
                    checkInPicker("AFTER",  idx: $afterIdx,  excluding: beforeIdx)
                }
            }
        }
        .onAppear { SBCheckInStore.shared.loadForClient(clientId) }
    }

    private func photoCard(checkIn: CheckInRow?, label: String, isLeft: Bool) -> some View {
        VStack(spacing: 6) {
            Text(label).font(.system(size: 9, weight: .black)).tracking(1)
                .foregroundColor(isLeft ? .white.opacity(0.4) : .tmGold)
            ZStack {
                if let ci = checkIn, let url = selectedAngle.url(from: ci),
                   let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(maxWidth: .infinity).frame(height: 200).clipped()
                } else {
                    RoundedRectangle(cornerRadius: 0).fill(Color.white.opacity(0.04))
                        .frame(maxWidth: .infinity).frame(height: 200)
                        .overlay(Image(systemName: "photo").font(.title2).foregroundColor(.white.opacity(0.2)))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(isLeft ? Color.white.opacity(0.08) : Color.tmGold.opacity(0.3), lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
    }

    private func checkInPicker(_ label: String, idx: Binding<Int>, excluding: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 9, weight: .black)).tracking(1).foregroundColor(.white.opacity(0.4))
            Menu {
                ForEach(checkIns.indices, id: \.self) { i in
                    if i != excluding {
                        Button(checkIns[i].formattedDate) { idx.wrappedValue = i }
                    }
                }
            } label: {
                HStack {
                    Text(checkIns[safe: idx.wrappedValue]?.formattedDate ?? "Select")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.caption2).foregroundColor(.tmGold)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tmGold.opacity(0.2), lineWidth: 1)))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Fullscreen photo

struct FullscreenPhotoView: View {
    let url: URL; let label: String
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFit().ignoresSafeArea()
            }
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8)).padding(16)
                    }
                }
                Spacer()
                Text(label).font(.caption).foregroundColor(.white.opacity(0.6)).padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Trainer Client Progress Dashboard

struct TrainerClientProgressDashboard: View {
    let clientId: String
    let clientName: String
    @State private var preferredUnit: SBWeightUnit = .lbs
    @State private var chartRange: ChartRange = .month

    enum ChartRange: String, CaseIterable {
        case week = "1W"; case month = "1M"; case three = "3M"; case all = "All"
    }

    private var allEntries: [SBWeightEntryRow] { SBWeightStore.shared.entries(forClient: clientId) }

    private var filteredEntries: [SBWeightEntryRow] {
        let now = Date()
        switch chartRange {
        case .week:  return allEntries.filter { now.timeIntervalSince($0.loggedAt ?? .distantPast) < 7  * 86400 }
        case .month: return allEntries.filter { now.timeIntervalSince($0.loggedAt ?? .distantPast) < 30 * 86400 }
        case .three: return allEntries.filter { now.timeIntervalSince($0.loggedAt ?? .distantPast) < 90 * 86400 }
        case .all:   return allEntries
        }
    }

    private var startWeight: Double? {
        SBWeightStore.shared.startingWeight(forClient: clientId)
            .map { preferredUnit == .lbs ? $0.weightInLbs : $0.weightInKg }
    }
    private var currentWeight: Double? {
        SBWeightStore.shared.latestWeight(forClient: clientId)
            .map { preferredUnit == .lbs ? $0.weightInLbs : $0.weightInKg }
    }
    private var totalChange: Double? {
        guard let s = startWeight, let c = currentWeight else { return nil }
        return c - s
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                weightSummaryCards
                weightChartSection
                Divider().background(Color.white.opacity(0.08))
                beforeAfterSection
            }
            .padding(20)
        }
        .background(Color.black)
        .onAppear { SBWeightStore.shared.loadForClient(clientId) }
    }

    private var weightSummaryCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("WEIGHT PROGRESS")
                Spacer()
                HStack(spacing: 0) {
                    unitButton("lbs", selected: preferredUnit == .lbs) { preferredUnit = .lbs }
                    unitButton("kg",  selected: preferredUnit == .kg)  { preferredUnit = .kg  }
                }
            }
            HStack(spacing: 10) {
                weightCard("Start",   value: startWeight,   color: .white.opacity(0.6))
                weightCard("Current", value: currentWeight, color: .tmGold)
                weightCard("Goal",    value: nil,           color: .green)
            }
            if let change = totalChange {
                let isLoss = change < 0
                let color: Color = isLoss ? .green : change == 0 ? .white.opacity(0.4) : .orange
                HStack(spacing: 8) {
                    Image(systemName: isLoss ? "arrow.down.circle.fill" : "arrow.up.circle.fill").foregroundColor(color)
                    Text(String(format: "%@%.1f %@ total change", isLoss ? "↓ " : "↑ ", abs(change), preferredUnit.rawValue))
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(color)
                    Spacer()
                    Text("\(allEntries.count) entries").font(.caption2).foregroundColor(.white.opacity(0.35))
                }
                .padding(10).background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.08)))
            }
        }
    }

    private var weightChartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("WEIGHT TREND")
                Spacer()
                HStack(spacing: 4) {
                    ForEach(ChartRange.allCases, id: \.self) { range in
                        Button(action: { chartRange = range }) {
                            Text(range.rawValue).font(.system(size: 11, weight: .bold))
                                .foregroundColor(chartRange == range ? .black : .white.opacity(0.4))
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Capsule().fill(chartRange == range ? Color.tmGold : Color.white.opacity(0.08)))
                        }
                    }
                }
            }
            WeightTrendChart(entries: filteredEntries, unit: preferredUnit, accentColor: .tmGold)
                .padding(14).background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
        }
    }

    private var beforeAfterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("BEFORE / AFTER COMPARISON")
            BeforeAfterComparatorView(clientId: clientId)
        }
    }

    private func weightCard(_ label: String, value: Double?, color: Color) -> some View {
        VStack(spacing: 4) {
            if let v = value {
                Text(String(format: "%.1f", v)).font(.system(size: 20, weight: .black)).foregroundColor(color)
                Text(preferredUnit.rawValue).font(.system(size: 10)).foregroundColor(color.opacity(0.6))
            } else {
                Text("—").font(.system(size: 20, weight: .black)).foregroundColor(.white.opacity(0.2))
                Text("N/A").font(.system(size: 10)).foregroundColor(.white.opacity(0.2))
            }
            Text(label).font(.system(size: 9, weight: .bold)).tracking(0.8).foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.07)))
    }

    private func unitButton(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 11, weight: .bold))
                .foregroundColor(selected ? .black : .white.opacity(0.4))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(selected ? Color.tmGold : Color.clear)
        }.buttonStyle(.plain)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
    }
}

// MARK: - Client Progress Section

struct ClientProgressSection: View {
    let clientId:  String
    let trainerId: String
    @State private var preferredUnit: SBWeightUnit = .lbs

    private var entries: [SBWeightEntryRow] {
        Array(SBWeightStore.shared.entries(forClient: clientId).suffix(14))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Progress").font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Text("Weight trend & photo comparison").font(.caption).foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                HStack(spacing: 0) {
                    unitBtn("lbs", preferredUnit == .lbs) { preferredUnit = .lbs }
                    unitBtn("kg",  preferredUnit == .kg)  { preferredUnit = .kg  }
                }
            }
            WeightTrendChart(entries: entries, unit: preferredUnit, accentColor: .tmGold)
                .padding(14).background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
            VStack(alignment: .leading, spacing: 10) {
                Text("PHOTO COMPARISON").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                BeforeAfterComparatorView(clientId: clientId)
            }
        }
        .onAppear { SBWeightStore.shared.loadForClient(clientId) }
    }

    private func unitBtn(_ label: String, _ selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 11, weight: .bold))
                .foregroundColor(selected ? .black : .white.opacity(0.4))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(selected ? Color.tmGold : Color.clear)
        }.buttonStyle(.plain)
    }
}
