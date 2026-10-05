import SwiftUI
import SwiftData

struct ThrowBlock: Identifiable {
    let id = UUID()
    var distance: Int
    var count: Int
}

struct ExecutionFlowView: View {
    let routine: Routine

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    enum Phase { case checkIn, guided, wrapUp, log }

    @State private var phase: Phase = .checkIn
    @State private var armStatus = "Good"
    @State private var readiness = 7.0
    @State private var focus = 7.0
    @State private var stepIndex = 0

    // Progress and choices, kept here so they survive moving between steps
    @State private var checked: Set<UUID> = []
    @State private var pathChoice: [UUID: UUID] = [:]   // step id -> stretch path id
    @State private var plyoChoice: [UUID: UUID] = [:]   // step id -> plyo type id
    @State private var throwChoice: [UUID: UUID] = [:]  // step id -> throw option id
    @State private var catchDistance = 75

    // Long toss blocks (editable)
    @State private var blocks: [ThrowBlock] = [
        ThrowBlock(distance: 60, count: 10),
        ThrowBlock(distance: 90, count: 10),
        ThrowBlock(distance: 120, count: 8),
        ThrowBlock(distance: 150, count: 8),
        ThrowBlock(distance: 90, count: 10)
    ]

    // Live day
    @State private var livePitches = 20
    @State private var simAB = false
    @State private var abCount = 1
    @State private var abPitches = 5

    // Wrap-up
    @AppStorage("recoveryCycleIndex") private var recoveryCycleIndex = 0
    @State private var wrapChoice: WrapUpOption?
    @State private var recoveryColor: RecoveryColor?

    // Bullpen
    @State private var goal: BullpenGoal?
    @State private var pitchesThrown = 0
    @State private var onTarget = 0
    @State private var velos: [String] = Array(repeating: "", count: 25)

    // Post-workout
    @State private var fatigue = 3.0
    @State private var throwsCompleted = 0
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .checkIn: checkIn
                case .guided:  guided
                case .wrapUp:  wrapUp
                case .log:     postLog
                }
            }
            .appScreen()
            .navigationTitle(routine.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }

    // MARK: Pre-workout check-in

    @ViewBuilder private var checkIn: some View {
        Form {
            Picker("Arm Status", selection: $armStatus) {
                ForEach(["Great", "Good", "Tight", "Sore"], id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
            Section("Readiness: \(Int(readiness))/10") { Slider(value: $readiness, in: 1...10, step: 1) }
            Section("Mental Focus: \(Int(focus))/10") { Slider(value: $focus, in: 1...10, step: 1) }
            Button("Begin Routine") { phase = .guided }.bold()
        }
    }

    // MARK: Guided steps

    @ViewBuilder private var guided: some View {
        let step = routine.steps[stepIndex]
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: Double(stepIndex + 1), total: Double(routine.steps.count))
                Text("Step \(stepIndex + 1) of \(routine.steps.count)")
                    .font(.caption).foregroundColor(.secondary)
                Text(step.title).font(.title2).bold()
                Text(step.subtitle).font(.subheadline).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            ScrollView {
                stepContent(step)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }

            Divider()
            HStack {
                Button("Back") { stepIndex -= 1 }
                    .disabled(stepIndex == 0)
                Spacer()
                if stepIndex < routine.steps.count - 1 {
                    Button("Next") { stepIndex += 1 }.buttonStyle(.borderedProminent)
                } else {
                    Button("Finish") { phase = .wrapUp }.buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func stepContent(_ step: RoutineStep) -> some View {
        switch step.kind {
        case .checklist(let drillItems): checklistView(drillItems)
        case .paths(let paths):          pathsView(step, paths)
        case .plyos(let types):          plyosView(step, types)
        case .throwChoice(let options):  throwChoiceView(step, options)
        case .throwBlocks:               throwBlocksView
        case .live:                      liveView
        case .bullpen:                   bullpenView
        }
    }

    // MARK: Checklist

    private func toggle(_ id: UUID) {
        if checked.contains(id) { checked.remove(id) } else { checked.insert(id) }
    }

    private func toggleRow(id: UUID, title: String, detail: String) -> some View {
        let done = checked.contains(id)
        return Button { toggle(id) } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(done ? .green : .gray)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body).fontWeight(.medium)
                    Text(detail).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.card))
        }
        .buttonStyle(.plain)
    }

    private func checklistView(_ list: [DrillItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(list.enumerated()), id: \.element.id) { index, item in
                VStack(alignment: .leading, spacing: 8) {
                    if !item.group.isEmpty && (index == 0 || list[index - 1].group != item.group) {
                        Text(item.group).font(.headline).padding(.top, 6)
                    }
                    toggleRow(id: item.id, title: item.name, detail: item.detail)
                }
            }
        }
    }

    // MARK: Stretch paths

    private func optionButton(_ title: String, selected: Bool, tint: Color = AppTheme.accent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption).bold()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? tint : AppTheme.card))
                .foregroundColor(selected ? .white : .primary)
        }
    }

    private func pathsView(_ step: RoutineStep, _ paths: [StretchPath]) -> some View {
        let chosen = paths.first(where: { $0.id == pathChoice[step.id] })
        return VStack(alignment: .leading, spacing: 12) {
            Text("Choose a path").font(.headline)
            HStack(spacing: 8) {
                ForEach(paths) { path in
                    optionButton(path.name, selected: chosen?.id == path.id) {
                        pathChoice[step.id] = path.id
                    }
                }
            }
            if let chosen {
                checklistView(chosen.items)
            }
        }
    }

    // MARK: Plyos

    private func plyosView(_ step: RoutineStep, _ types: [PlyoType]) -> some View {
        let chosen: PlyoType? = types.count == 1
            ? types.first
            : types.first(where: { $0.id == plyoChoice[step.id] })

        return VStack(alignment: .leading, spacing: 12) {
            if types.count > 1 {
                Text("Choose a plyo day").font(.headline)
                HStack(spacing: 8) {
                    ForEach(types) { type in
                        optionButton(type.name, selected: chosen?.id == type.id) {
                            plyoChoice[step.id] = type.id
                        }
                    }
                }
            }
            if let chosen {
                Text(chosen.name).font(.headline)
                Text(chosen.note).font(.caption).foregroundColor(.secondary)
                ForEach(chosen.items) { item in
                    toggleRow(
                        id: item.id,
                        title: item.name,
                        detail: "\(item.sets)  ·  \(item.weight)  ·  \(item.percent)"
                    )
                }
            }
        }
    }

    // MARK: Bullpen

    private var velocityStats: (peak: Double, avg: Double)? {
        let values = velos.compactMap { Double($0) }.filter { $0 > 0 }
        guard !values.isEmpty else { return nil }
        return (values.max() ?? 0, values.reduce(0, +) / Double(values.count))
    }

    @ViewBuilder private var bullpenView: some View {
        if let goal {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(goal.rawValue, systemImage: goal.icon)
                        .font(.headline).foregroundColor(AppTheme.accent)
                    Spacer()
                    Button("Change Goal") { self.goal = nil }.font(.caption)
                }
                Text("\(goal.totalPitches) pitches  ·  \(goal.intent)")
                    .font(.subheadline).bold()

                ForEach(Array(goal.blocks.enumerated()), id: \.offset) { index, block in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption).bold()
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color.blue))
                            .foregroundColor(.white)
                        Text(block).font(.subheadline)
                    }
                }

                Divider()
                Stepper("Pitches thrown: \(pitchesThrown)", value: $pitchesThrown, in: 0...120)
                if goal == .command {
                    Stepper("Pitches on target: \(onTarget)", value: $onTarget, in: 0...120)
                }
                if goal.veloSlots > 0 {
                    velocityInputs
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("What do you want to get out of this?")
                    .font(.title3).bold()
                ForEach(BullpenGoal.allCases) { option in
                    Button {
                        goal = option
                        pitchesThrown = option.totalPitches
                        onTarget = 0
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: option.icon)
                                .font(.title3).foregroundColor(AppTheme.accent).frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.rawValue).font(.headline)
                                Text(option.tagline).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.secondary)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder private var velocityInputs: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Record velocities (mph)").font(.headline)
            if let stats = velocityStats {
                Text(String(format: "Peak %.1f  ·  Avg %.1f", stats.peak, stats.avg))
                    .font(.subheadline).foregroundColor(AppTheme.accent)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                ForEach(velos.indices, id: \.self) { i in
                    TextField("\(i + 1)", text: $velos[i])
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: Long toss blocks

    @ViewBuilder private var throwBlocksView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach($blocks) { $block in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button { toggle(block.id) } label: {
                            Image(systemName: checked.contains(block.id) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(checked.contains(block.id) ? .green : .gray)
                        }
                        Text("\(block.count) throws at \(block.distance) ft").font(.headline)
                        Spacer()
                        Button(role: .destructive) {
                            blocks.removeAll { $0.id == block.id }
                        } label: { Image(systemName: "trash") }
                    }
                    Stepper("Distance: \(block.distance) ft", value: $block.distance, in: 30...400, step: 5)
                    Stepper("Throws: \(block.count)", value: $block.count, in: 1...50)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.card))
            }

            Button {
                blocks.append(ThrowBlock(distance: blocks.last?.distance ?? 90, count: 10))
            } label: {
                Label("Add Block", systemImage: "plus.circle.fill").bold()
            }

            Text("Total: \(blocks.reduce(0) { $0 + $1.count }) throws  ·  Max \(blocks.map(\.distance).max() ?? 0) ft")
                .font(.caption).foregroundColor(.secondary)
        }
    }

    // MARK: Live day

    private let liveBlocks = [
        "8 fastballs, building to normal bullpen intent",
        "8 secondary pitches at the same intent",
        "4 pitches from the stretch"
    ]

    @ViewBuilder private var liveView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Normal bullpen intent  ·  under 25 pitches").font(.subheadline).bold()
            ForEach(Array(liveBlocks.enumerated()), id: \.offset) { index, block in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption).bold()
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(AppTheme.accent))
                        .foregroundColor(.white)
                    Text(block).font(.subheadline)
                }
            }
            Stepper("Pre-live pitches thrown: \(livePitches)", value: $livePitches, in: 0...24)

            Divider()
            Toggle("Add a simulated at-bat", isOn: $simAB)
            if simAB {
                Text("Picture a hitter or use a live batter. Start 0-0 and work the count with game intent.")
                    .font(.caption).foregroundColor(.secondary)
                Stepper("At-bats: \(abCount)", value: $abCount, in: 1...5)
                Stepper("Pitches in at-bats: \(abPitches)", value: $abPitches, in: 0...40)
            }
        }
    }

    // MARK: Throwing options (recovery day)

    private func throwChoiceView(_ step: RoutineStep, _ options: [ThrowOption]) -> some View {
        let chosen = options.first(where: { $0.id == throwChoice[step.id] })
        return VStack(alignment: .leading, spacing: 12) {
            if let chosen {
                HStack {
                    Label(chosen.name, systemImage: chosen.icon)
                        .font(.headline).foregroundColor(AppTheme.accent)
                    Spacer()
                    Button("Change") { throwChoice[step.id] = nil }.font(.caption)
                }
                Text(chosen.summary).font(.subheadline).foregroundColor(.secondary)
                if chosen.hasDistance {
                    Stepper("Max distance: \(catchDistance) ft", value: $catchDistance, in: 30...90, step: 5)
                }
                if let plyo = chosen.plyo {
                    ForEach(plyo.items) { item in
                        toggleRow(id: item.id, title: item.name,
                                  detail: "\(item.sets)  ·  \(item.weight)  ·  \(item.percent)")
                    }
                } else if chosen.isNoThrow {
                    Text("No throwing today. Tap Finish to move on to wrap-up.").font(.subheadline)
                } else {
                    checklistView(chosen.blocks)
                }
            } else {
                Text("How do you want to throw today?").font(.title3).bold()
                ForEach(options) { option in
                    Button { throwChoice[step.id] = option.id } label: {
                        HStack(spacing: 12) {
                            Image(systemName: option.icon)
                                .font(.title3).foregroundColor(AppTheme.accent).frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.name).font(.headline)
                                Text(option.summary).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.secondary)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Wrap-up (after every day)

    @ViewBuilder private var wrapUp: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let choice = wrapChoice {
                        HStack {
                            Label(choice.rawValue, systemImage: choice.icon).font(.title3).bold()
                            Spacer()
                            Button("Change") { wrapChoice = nil }.font(.caption)
                        }
                        wrapContent(choice)
                    } else {
                        Text("Wrap Up").font(.title2).bold()
                        Text("Choose how to finish today's session.")
                            .font(.subheadline).foregroundColor(.secondary)
                        ForEach(routine.wrapUpOptions) { option in
                            Button {
                                if option == .skip { phase = .log } else { wrapChoice = option }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: option.icon)
                                        .font(.title3).foregroundColor(AppTheme.accent).frame(width: 32)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(option.rawValue).font(.headline)
                                        Text(option.tagline).font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                                }
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            Divider()
            HStack {
                Button("Back") { phase = .guided }
                Spacer()
                if wrapChoice != nil {
                    Button("Finish") { phase = .log }.buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func wrapContent(_ choice: WrapUpOption) -> some View {
        switch choice {
        case .postThrow: postThrowView
        case .medBall:   checklistView(PostThrowLibrary.medBall)
        case .waterball: checklistView(PostThrowLibrary.waterball)
        case .skip:      EmptyView()
        }
    }

    private var suggestedColor: RecoveryColor {
        RecoveryColor.allCases[recoveryCycleIndex % RecoveryColor.allCases.count]
    }

    @ViewBuilder private var postThrowView: some View {
        let color = recoveryColor ?? suggestedColor
        VStack(alignment: .leading, spacing: 10) {
            Text("Colors rotate each session. Today's suggestion: \(suggestedColor.rawValue).")
                .font(.caption).foregroundColor(.secondary)
            HStack(spacing: 8) {
                ForEach(RecoveryColor.allCases) { c in
                    optionButton(c.rawValue, selected: color == c, tint: c.tint) {
                        recoveryColor = c
                    }
                }
            }
            checklistView([PostThrowLibrary.softTissue] + PostThrowLibrary.exercises(for: color))
        }
    }

    // MARK: Post-workout log

    @ViewBuilder private var postLog: some View {
        Form {
            Stepper("Throws / reps completed: \(throwsCompleted)", value: $throwsCompleted, in: 0...300, step: 5)
            Section("Arm fatigue: \(Int(fatigue))/10") { Slider(value: $fatigue, in: 1...10, step: 1) }
            Section("Notes") { TextField("How did it feel?", text: $notes, axis: .vertical) }
            Button("Save Session") { saveSession() }.bold()
        }
    }

    private var hasLongToss: Bool {
        routine.steps.contains { step in
            if case .throwBlocks = step.kind { return true } else { return false }
        }
    }

    private var hasLive: Bool {
        routine.steps.contains { step in
            if case .live = step.kind { return true } else { return false }
        }
    }

    private func saveSession() {
        var parts = [routine.name, "arm: \(armStatus)", "reps: \(throwsCompleted)", "fatigue: \(Int(fatigue))/10"]
        if let goal { parts.append("bullpen: \(goal.rawValue)") }
        for step in routine.steps {
            if case .throwChoice(let options) = step.kind,
               let picked = options.first(where: { $0.id == throwChoice[step.id] }) {
                parts.append("throwing: \(picked.name)" + (picked.hasDistance ? " (max \(catchDistance) ft)" : ""))
            }
        }
        let doneBlocks = blocks.filter { checked.contains($0.id) }
        if hasLongToss && !doneBlocks.isEmpty {
            parts.append("long toss: " + doneBlocks.map { "\($0.count)x\($0.distance)ft" }.joined(separator: ", "))
        }
        if hasLive {
            parts.append("live: \(livePitches) pre-live pitches" + (simAB ? ", \(abCount) sim AB (\(abPitches) pitches)" : ""))
        }
        if let wrapChoice { parts.append("wrap-up: \(wrapChoice.rawValue)") }
        if wrapChoice == .postThrow {
            let used = recoveryColor ?? suggestedColor
            parts.append("recovery color: \(used.rawValue)")
            recoveryCycleIndex = ((RecoveryColor.allCases.firstIndex(of: used) ?? 0) + 1) % RecoveryColor.allCases.count
        }
        if let stats = velocityStats {
            parts.append(String(format: "velo peak %.1f / avg %.1f", stats.peak, stats.avg))
        }
        if !notes.isEmpty { parts.append(notes) }

        let log = DailyLog(
            date: Date(),
            readinessScore: Int(readiness),
            mentalFocusScore: Int(focus),
            notes: parts.joined(separator: " | ")
        )

        if let goal {
            let pct = (goal == .command && pitchesThrown > 0)
                ? Double(onTarget) / Double(pitchesThrown) * 100
                : 0
            log.moundLog = MoundLog(pitchCount: pitchesThrown, strikePercentage: pct, pitchQualityScore: 0)
        }
        if let stats = velocityStats {
            let count = velos.compactMap { Double($0) }.filter { $0 > 0 }.count
            log.throwingLog = ThrowingLog(maxDistanceFeet: 0, highIntentThrows: count, peakVelocityMph: stats.peak)
        }

        if hasLive {
            log.moundLog = MoundLog(pitchCount: livePitches + (simAB ? abPitches : 0), strikePercentage: 0, pitchQualityScore: 0)
        }
        if hasLongToss && !doneBlocks.isEmpty && log.throwingLog == nil {
            log.throwingLog = ThrowingLog(
                maxDistanceFeet: Double(doneBlocks.map(\.distance).max() ?? 0),
                highIntentThrows: doneBlocks.reduce(0) { $0 + $1.count },
                peakVelocityMph: 0
            )
        }

        modelContext.insert(log)
        dismiss()
    }
}

extension RecoveryColor {
    var tint: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .purple: return .purple
        }
    }
}
