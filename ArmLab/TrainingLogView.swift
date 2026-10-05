import SwiftUI
import SwiftData
import UIKit

struct TrainingLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var dailyLogs: [DailyLog]

    @State private var selectedDate = Date()
    @State private var activeSection: TrainingSection = .warmUp

    // Cognitive State
    @State private var readinessScore: Int = 7
    @State private var mentalFocusScore: Int = 8

    // Warm-Up State
    @State private var warmUpRoutines: [WarmUpEntry] = BodyPart.allCases.map {
        WarmUpEntry(bodyPart: $0)
    }

    // Throwing State
    @State private var maxDistanceFt: Double = 120.0
    @State private var highIntentThrows: Int = 15
    @State private var peakVeloMph: Double = 90.0

    // Mound Work State
    @State private var pitchCount: Int = 30
    @State private var strikePercentage: Double = 65.0
    @State private var pitchQualityScore: Int = 4

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Date Selector & Quick Save Header
                HStack {
                    DatePicker("Training Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    Button("Save Log") {
                        saveCurrentLog()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.subheadline)
                    .bold()
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))

                // Section Chips Navigation Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(TrainingSection.allCases) { section in
                            CategoryChip(
                                title: section.rawValue,
                                icon: section.iconName,
                                isActive: activeSection == section
                            ) {
                                activeSection = section
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color(uiColor: .systemBackground))

                Divider()

                // Dynamic Content View
                ScrollView {
                    VStack(spacing: 16) {
                        mainContentSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Training Log")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var mainContentSection: some View {
        switch activeSection {
        case .cognitive: cognitiveSection
        case .warmUp:    warmUpSection
        case .throwing:  throwingSection
        case .moundWork: moundWorkSection
        case .lifting, .plyos, .medballs, .postCare: genericSection(for: activeSection)
        }
    }

    @ViewBuilder
    private var cognitiveSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cognitive & CNS Readiness")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Morning Readiness: \(readinessScore)/10")
                Slider(value: Binding(
                    get: { Double(readinessScore) },
                    set: { readinessScore = Int($0) }
                ), in: 1...10, step: 1)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))

            VStack(alignment: .leading, spacing: 8) {
                Text("Mental Focus / Intent: \(mentalFocusScore)/10")
                Slider(value: Binding(
                    get: { Double(mentalFocusScore) },
                    set: { mentalFocusScore = Int($0) }
                ), in: 1...10, step: 1)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
        }
    }

    @ViewBuilder
    private var warmUpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Targeted Warm-Up Routines")
                    .font(.headline)
                Spacer()
                Text("\(warmUpRoutines.filter(\.isCompleted).count)/\(warmUpRoutines.count) Done")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(warmUpRoutines, id: \.bodyPartRaw) { entry in
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Mobility Rating:")
                            Spacer()
                            Text("\(entry.mobilityScore)/10")
                                .bold()
                        }
                        Slider(value: Binding(
                            get: { Double(entry.mobilityScore) },
                            set: { newValue in
                                if let index = warmUpRoutines.firstIndex(where: { $0.bodyPartRaw == entry.bodyPartRaw }) {
                                    warmUpRoutines[index].mobilityScore = Int(newValue)
                                }
                            }
                        ), in: 1...10, step: 1)
                    }
                    .padding(.top, 8)
                } label: {
                    HStack {
                        Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(entry.isCompleted ? .green : .gray)
                            .onTapGesture {
                                if let index = warmUpRoutines.firstIndex(where: { $0.bodyPartRaw == entry.bodyPartRaw }) {
                                    warmUpRoutines[index].isCompleted.toggle()
                                }
                            }
                        Text(entry.bodyPart.rawValue)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
            }
        }
    }

    @ViewBuilder
    private var throwingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Throwing & Long Toss Workout")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                Text("Max Long Toss Distance: \(Int(maxDistanceFt)) ft")
                Slider(value: $maxDistanceFt, in: 60...350, step: 5)

                Divider()

                Stepper("High-Intent Throws: \(highIntentThrows)", value: $highIntentThrows, in: 0...60)

                Divider()

                HStack {
                    Text("Peak Velocity (mph):")
                    Spacer()
                    TextField("MPH", value: $peakVeloMph, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
        }
    }

    @ViewBuilder
    private var moundWorkSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mound Work & Bullpen Session")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                Stepper("Pitch Count: \(pitchCount)", value: $pitchCount, in: 0...120, step: 5)

                Divider()

                VStack(alignment: .leading) {
                    Text("Strike Zone %: \(Int(strikePercentage))%")
                    Slider(value: $strikePercentage, in: 0...100, step: 5)
                }

                Divider()

                VStack(alignment: .leading) {
                    Text("Session Quality Score: \(pitchQualityScore)/5")
                    Slider(value: Binding(
                        get: { Double(pitchQualityScore) },
                        set: { pitchQualityScore = Int($0) }
                    ), in: 1...5, step: 1)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
        }
    }

    @ViewBuilder
    private func genericSection(for section: TrainingSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(section.rawValue) Section")
                .font(.headline)
            Text("Track volume and specific notes for \(section.rawValue.lowercased()).")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
    }

    // MARK: - Persistence Action

    private func saveCurrentLog() {
        let newLog = DailyLog(
            date: selectedDate,
            readinessScore: readinessScore,
            mentalFocusScore: mentalFocusScore,
            notes: ""
        )

        let throwing = ThrowingLog(
            maxDistanceFeet: maxDistanceFt,
            highIntentThrows: highIntentThrows,
            peakVelocityMph: peakVeloMph
        )

        let mound = MoundLog(
            pitchCount: pitchCount,
            strikePercentage: strikePercentage,
            pitchQualityScore: pitchQualityScore
        )

        newLog.throwingLog = throwing
        newLog.moundLog = mound
        newLog.warmUpEntries = warmUpRoutines

        modelContext.insert(newLog)
    }
}

// MARK: - Enums & Components

enum TrainingSection: String, CaseIterable, Identifiable {
    case cognitive = "Cognitive"
    case warmUp = "Warm-Up"
    case plyos = "Plyos"
    case throwing = "Throwing"
    case moundWork = "Mound Work"
    case medballs = "Medballs"
    case lifting = "Lifting"
    case postCare = "Post Care"

    var id: String { self.rawValue }

    var iconName: String {
        switch self {
        case .cognitive: return "brain.head.profile"
        case .warmUp: return "figure.cooldown"
        case .plyos: return "bolt.fill"
        case .throwing: return "figure.baseball"
        case .moundWork: return "target"
        case .medballs: return "sportscourt.fill"
        case .lifting: return "dumbbell.fill"
        case .postCare: return "heart.text.square.fill"
        }
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isActive ? .bold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isActive ? Color.blue : Color(uiColor: .tertiarySystemFill))
            .foregroundColor(isActive ? .white : .primary)
            .cornerRadius(20)
        }
    }
}
