import SwiftUI

struct IndexGroup {
    let heading: String
    var lines: [String]
}

struct IndexSection {
    let title: String
    let groups: [IndexGroup]
}

/// A read-only table of contents listing every drill in every section.
/// Built from the routine library, so adding a drill there updates this automatically.
struct DrillIndexView: View {
    private let sections = DrillIndexView.makeSections()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Drill Index")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("Every drill in every section.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(index + 1). \(section.title)")
                        .font(.headline)
                        .foregroundColor(AppTheme.accent)

                    ForEach(Array(section.groups.enumerated()), id: \.offset) { _, group in
                        VStack(alignment: .leading, spacing: 4) {
                            if !group.heading.isEmpty {
                                Text(group.heading)
                                    .font(.subheadline)
                                    .bold()
                            }
                            ForEach(Array(group.lines.enumerated()), id: \.offset) { _, line in
                                Text("•  \(line)")
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.card))
            }
        }
    }

    // MARK: - Building the index

    private static func checklist(_ step: RoutineStep) -> [DrillItem] {
        if case .checklist(let list) = step.kind { return list }
        return []
    }

    private static func paths(_ step: RoutineStep) -> [StretchPath] {
        if case .paths(let list) = step.kind { return list }
        return []
    }

    /// Groups consecutive drills that share a heading, keeping the original order.
    private static func grouped(_ list: [DrillItem]) -> [IndexGroup] {
        var result: [IndexGroup] = []
        for item in list {
            if let last = result.last, last.heading == item.group {
                result[result.count - 1].lines.append(item.name)
            } else {
                result.append(IndexGroup(heading: item.group, lines: [item.name]))
            }
        }
        return result
    }

    private static func makeSections() -> [IndexSection] {
        var out: [IndexSection] = []

        out.append(IndexSection(title: "Roll Out",
                                groups: grouped(checklist(RoutineLibrary.rollOut))))

        var stretchGroups: [IndexGroup] = []
        for path in paths(RoutineLibrary.staticStretch) {
            stretchGroups.append(IndexGroup(heading: "Path: \(path.name)", lines: []))
            stretchGroups += grouped(path.items).map {
                IndexGroup(heading: $0.heading.isEmpty ? "" : "   \($0.heading)", lines: $0.lines)
            }
        }
        out.append(IndexSection(title: "Static Stretching", groups: stretchGroups))

        out.append(IndexSection(title: "Dynamic Warm-Up",
                                groups: grouped(checklist(RoutineLibrary.dynamicWarmUp))))

        out.append(IndexSection(title: "Pre-Throw",
                                groups: grouped(checklist(RoutineLibrary.preThrow))))

        out.append(IndexSection(title: "Pre-Throw (Bullpen & Live Days)",
                                groups: grouped(checklist(RoutineLibrary.preThrowBullpen))))

        var plyoGroups: [IndexGroup] = []
        for type in [PlyoLibrary.half, PlyoLibrary.a, PlyoLibrary.b, PlyoLibrary.c] {
            plyoGroups.append(IndexGroup(heading: type.name, lines: type.items.map { $0.name }))
        }
        out.append(IndexSection(title: "Plyo Ball Work", groups: plyoGroups))

        var throwGroups: [IndexGroup] = []
        for option in ThrowLibrary.options where !option.blocks.isEmpty {
            throwGroups.append(IndexGroup(heading: option.name, lines: option.blocks.map { $0.name }))
        }
        throwGroups.append(IndexGroup(
            heading: "Long Toss",
            lines: ["Build your own blocks of distance and number of throws"]))
        out.append(IndexSection(title: "Throwing", groups: throwGroups))

        var penGroups: [IndexGroup] = []
        for goal in BullpenGoal.allCases {
            penGroups.append(IndexGroup(
                heading: "\(goal.rawValue): \(goal.totalPitches) pitches, \(goal.intent)",
                lines: goal.blocks))
        }
        penGroups.append(IndexGroup(
            heading: "Pre-Live Bullpen: under 25 pitches, normal pen intent",
            lines: LiveBullpen.blocks + ["Optional simulated at-bat"]))
        out.append(IndexSection(title: "Bullpen & Live", groups: penGroups))

        out.append(IndexSection(title: "Med Ball Routine",
                                groups: [IndexGroup(heading: "", lines: PostThrowLibrary.medBall.map { $0.name })]))

        out.append(IndexSection(title: "Waterball Routine",
                                groups: [IndexGroup(heading: "", lines: PostThrowLibrary.waterball.map { $0.name })]))

        var recoveryGroups: [IndexGroup] = [
            IndexGroup(heading: "Every Day", lines: [PostThrowLibrary.softTissue.name])
        ]
        for color in RecoveryColor.allCases {
            recoveryGroups.append(IndexGroup(
                heading: "\(color.rawValue) Day",
                lines: PostThrowLibrary.exercises(for: color).map { $0.name }))
        }
        out.append(IndexSection(title: "Post-Throw Recovery", groups: recoveryGroups))

        return out
    }
}

/// Full-screen page that opens from the dashboard's "Drill Library" button.
struct DrillLibraryScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                DrillIndexView()
                    .padding()
            }
            .appScreen()
            .navigationTitle("Drill Library")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button {
                    dismiss()
                } label: {
                    Label("Exit to Dashboard", systemImage: "house.fill")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
}
