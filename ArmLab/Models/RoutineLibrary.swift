import Foundation

// MARK: - Step content models

struct DrillItem: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    var group: String = ""
}

struct StretchPath: Identifiable {
    let id = UUID()
    let name: String
    let items: [DrillItem]
}

struct PlyoItem: Identifiable {
    let id = UUID()
    let name: String
    let sets: String
    let weight: String
    let percent: String
}

struct PlyoType: Identifiable {
    let id = UUID()
    let name: String
    let note: String
    let items: [PlyoItem]
}

enum StepKind {
    case checklist([DrillItem])
    case paths([StretchPath])
    case plyos([PlyoType])
    case throwChoice([ThrowOption])
    case bullpen
}

struct RoutineStep: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let kind: StepKind
}

struct Routine: Identifiable {
    let id = UUID()
    let name: String
    let dayType: DayType
    let steps: [RoutineStep]
}

struct ThrowOption: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let summary: String
    var plyo: PlyoType? = nil
    var blocks: [DrillItem] = []
    var hasDistance = false
    var isNoThrow = false
}

enum RecoveryColor: String, CaseIterable, Identifiable {
    case red = "Red", blue = "Blue", purple = "Purple"
    var id: String { rawValue }
}

enum WrapUpOption: String, CaseIterable, Identifiable {
    case postThrow = "Post-Throw Recovery"
    case medBall = "Med Ball Routine"
    case waterball = "Waterball Routine"
    case skip = "No Post-Throw"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .postThrow: return "heart.text.square"
        case .medBall: return "sportscourt"
        case .waterball: return "drop.fill"
        case .skip: return "xmark.circle"
        }
    }

    var tagline: String {
        switch self {
        case .postThrow: return "Soft tissue plus today's rotating color"
        case .medBall: return "Rotational and explosive med ball work"
        case .waterball: return "Hops, swings, and pitch patterns"
        case .skip: return "Skip it and log the session"
        }
    }
}

private func items(_ rows: [(String, String)], group: String = "") -> [DrillItem] {
    rows.map { DrillItem(name: $0.0, detail: $0.1, group: group) }
}

private func ply(_ name: String, _ sets: String, _ weight: String, _ percent: String) -> PlyoItem {
    PlyoItem(name: name, sets: sets, weight: weight, percent: percent)
}

// MARK: - Bullpen goals

enum BullpenGoal: String, CaseIterable, Identifiable {
    case command = "Command"
    case pitchDesign = "Pitch Design"
    case feelGood = "Feel-Good"
    case velocity = "Velocity"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .command: return "scope"
        case .pitchDesign: return "wand.and.stars"
        case .feelGood: return "face.smiling"
        case .velocity: return "speedometer"
        }
    }

    var tagline: String {
        switch self {
        case .command: return "Hit your spots and work the zone"
        case .pitchDesign: return "Shape, grip, and feel for each pitch"
        case .feelGood: return "Short, easy, and smooth"
        case .velocity: return "Max intent, track every fastball"
        }
    }

    var totalPitches: Int {
        switch self {
        case .command: return 40
        case .pitchDesign: return 35
        case .feelGood: return 20
        case .velocity: return 50
        }
    }

    var intent: String {
        switch self {
        case .command: return "80-85% intent"
        case .pitchDesign: return "75-85% intent"
        case .feelGood: return "60-70% intent"
        case .velocity: return "95-100% intent"
        }
    }

    var blocks: [String] {
        switch self {
        case .command:
            return ["10 fastballs to the middle of the zone to find rhythm",
                    "15 fastballs alternating glove-side and arm-side corners",
                    "10 secondary pitches to a specific target",
                    "5 situational pitches (ahead in the count, then behind)"]
        case .pitchDesign:
            return ["10 pitches: primary pitch, focus on grip and release feel",
                    "10 pitches: secondary pitch, change one variable (pressure, finger position)",
                    "10 pitches: try a new grip or shape",
                    "5 pitches: your best version, record the data or video"]
        case .feelGood:
            return ["8 fastballs, smooth and easy",
                    "6 changeups, full arm speed with relaxed effort",
                    "6 breaking balls, no max effort"]
        case .velocity:
            return ["10 fastballs building from 70% to 90%",
                    "25 max-intent fastballs (record every velocity below)",
                    "10 offspeed pitches at 85%",
                    "5 easy cool-down throws"]
        }
    }

    var veloSlots: Int { self == .velocity ? 25 : 0 }
}

// MARK: - Plyo routines (from your Plyo Routines Key)

enum PlyoLibrary {
    static let half = PlyoType(
        name: "Half Plyos",
        note: "Lower intent days. Stay smooth at about 50%.",
        items: [
            ply("Pivots", "2 x 6", "Green", "50%"),
            ply("REV Throw", "2 x 6", "No ball", "50%"),
            ply("Bauers", "2 x 6", "Yellow/Gray", "50%"),
            ply("Walk Ins", "2 x 6", "Yellow/Gray", "50%")
        ])

    static let a = PlyoType(
        name: "Full Plyos A (Arm Path)",
        note: "Higher intent day without a bullpen. Always reverse throw.",
        items: [
            ply("Pivots", "2 x 8-10 each", "Green", "50-75%"),
            ply("REV Throw", "2 x 8-10 each", "No ball", "50-75%"),
            ply("Pre Set 90 Walk Ins", "2 x 3-5 each", "Red/Gray", "50-75%"),
            ply("1/2 Kneeling Figure 8s", "2 x 3-5 each", "Yellow/Gray", "50-75%"),
            ply("Standing Figure 8s", "2 x 3-5 each", "Yellow/Gray", "50-75%"),
            ply("Toss Ups", "2 x 3-5 each", "Yellow/Gray", "50-75%"),
            ply("Pre Set 90 Pick Offs", "2 x 3-5 each", "Yellow/Gray", "50-75%")
        ])

    static let b = PlyoType(
        name: "Full Plyos B (Light)",
        note: "Lighter higher intent day without a bullpen. Always reverse throw.",
        items: [
            ply("Pivots", "2 x 8-10 each", "Green", "50-75%"),
            ply("REV Throw", "2 x 8-10 each", "No ball", "50-75%"),
            ply("Leg Swings", "2 x 8-10 each", "Yellow/Gray", "50-75%"),
            ply("Bauers", "2 x 3-5 each", "Yellow/Gray", "50-75%"),
            ply("Darvish", "2 x 3-5 each", "Yellow/Gray", "50-75%"),
            ply("Yamamotos", "2 x 6", "Yellow/Gray", "50-75%")
        ])

    static let c = PlyoType(
        name: "Plyo C (A + B)",
        note: "Bullpen day: every A and B exercise, shared drills done once.",
        items: PlyoLibrary.a.items + PlyoLibrary.b.items.filter { item in
            !PlyoLibrary.a.items.contains { $0.name == item.name }
        })
}

// MARK: - Routine library

enum RoutineLibrary {

    // Step 1: roll out
    static let rollOut = RoutineStep(
        title: "Roll Out",
        subtitle: "Move slowly and pause on tight spots. About 8 minutes total.",
        kind: .checklist(items([
            ("Back & Spine", "Foam roller across the upper and mid back, hands behind head. 60 sec."),
            ("Glutes & Hips", "Cross ankle over knee and roll the glute. 45 sec each side."),
            ("Hamstrings (L & R)", "Roll from knee to glute. 45 sec each leg."),
            ("Quads (L & R)", "Face down, roll from hip to knee. 45 sec each leg."),
            ("Adductors (L & R)", "Leg out to the side, roll the inner thigh. 45 sec each leg."),
            ("Lats", "Side-lying, roll from armpit to ribs. 45 sec each side."),
            ("Feet (Lacrosse Ball)", "Roll arch, heel, and ball of the foot. 60 sec each foot.")
        ])))

    // Hip + thoracic mobility from your sheet (2 ER / 2 IR hip, 4 thoracic per day)
    static let mobilityPath: StretchPath = {
        var list: [DrillItem] = []
        list += items([
            ("Frog Pose", "2 x 20 sec."),
            ("Pigeon Pose", "2 x 20 sec."),
            ("Valslide V's", "2 x 8."),
            ("Lying Banded Med Ball Abduction", "2 x 8 each."),
            ("Banded Clams", "2 x 8.")
        ], group: "Hip Mobility: ER Focus (pick 2)")
        list += items([
            ("90/90 IR Holds", "2 x 20 sec."),
            ("Floor Squeezes / Med Ball Squeezes", "2 x 20 sec."),
            ("Seated IR Pulses", "2 x 8."),
            ("Quadruped Banded Over the Cone", "2 x 8.")
        ], group: "Hip Mobility: IR Focus (pick 2)")
        list += items([
            ("Hip Series", "2 x 8. Counts as one ER and one IR."),
            ("Valslide ER/IR Rotations", "2 x 8 each. Counts as one ER and one IR.")
        ], group: "Hip Mobility: ER/IR Combo")
        list += items([
            ("Seated Thoracic Rotations", "2 x 8."),
            ("Lying Sweeps", "2 x 8."),
            ("Dissociation Rolls", "2 x 8."),
            ("Kneeling PVC Valslide Thread the Needle", "2 x 8."),
            ("Lying Med Ball Back Extension Holds", "2 x 8."),
            ("Kneeling Plate Rolls", "2 x 8."),
            ("Split Stance Med Ball Hugs", "2 x 8."),
            ("Jefferson Curls", "2 x 8."),
            ("Barbell Rotations", "2 x 8.")
        ], group: "Thoracic Mobility (pick 4)")
        return StretchPath(name: "Mobility & Range of Motion", items: list)
    }()

    // Step 2: static stretching with three paths
    static let staticStretch = RoutineStep(
        title: "Static Stretching",
        subtitle: "Pick the path that fits how you feel today. Hold each stretch 30 sec per side.",
        kind: .paths([
            mobilityPath,
            StretchPath(name: "Lower Half", items: items([
                ("Hamstring Stretch", "Leg elevated, hinge at the hips."),
                ("Quad Stretch", "Standing or kneeling, heel to glute."),
                ("Hip Flexor Lunge Stretch", "Half-kneeling, squeeze the back glute."),
                ("Adductor Rock-Back", "Quadruped with one leg out, rock back."),
                ("Figure-4 Glute Stretch", "Ankle over knee, pull the leg toward you."),
                ("Calf Stretch", "Hands on wall, back heel down.")
            ])),
            StretchPath(name: "Upper Half", items: items([
                ("Sleeper Stretch", "Side-lying, gently press the forearm toward the floor."),
                ("Cross-Body Shoulder Stretch", "Pull the arm across the chest."),
                ("Doorway Pec Stretch", "Elbow at shoulder height, lean through."),
                ("Lat Stretch (Child's Pose Reach)", "Reach long and sink the hips back."),
                ("Triceps Overhead Stretch", "Elbow overhead, gentle pull."),
                ("Wrist Flexor / Extensor Stretch", "Arm straight, pull fingers back then down.")
            ]))
        ]))

    // Step 3: dynamic warm-up
    static let dynamicWarmUp = RoutineStep(
        title: "Dynamic Warm-Up",
        subtitle: "Raise your heart rate and get ready for pre-throw. About 5 minutes.",
        kind: .checklist(items([
            ("Jump Rope", "2 min, easy rhythm."),
            ("Jumping Jacks", "30 sec."),
            ("High Knees", "2 x 20 yd."),
            ("Butt Kicks", "2 x 20 yd."),
            ("Walking Lunge with Rotation", "10 each side."),
            ("Lateral Shuffle", "2 x 20 yd each direction."),
            ("Carioca", "2 x 20 yd each direction."),
            ("Skips", "2 x 20 yd, stay tall and loose.")
        ])))

    // Step 4a: standard pre-throw (from your Pre-Throwing Warm Up sheet)
    static let preThrow: RoutineStep = {
        var list: [DrillItem] = []
        list += items([
            ("3-Way Arm Walks", "Controlled reps.")
        ], group: "Arm Prep")
        list += items([
            ("0 ER/IR", "2 x 10."),
            ("90 ER/IR", "2 x 10."),
            ("Flys", "2 x 10."),
            ("Angels", "2 x 10."),
            ("Triceps", "2 x 10."),
            ("Split Stance Reaches", "2 x 10."),
            ("0 Flexion/Extension", "2 x 10."),
            ("90 Flexion/Extension", "2 x 10."),
            ("Radial Deviation", "2 x 10."),
            ("Ulnar Deviation", "2 x 10."),
            ("Pronation", "2 x 10."),
            ("Supination", "2 x 10.")
        ], group: "Band Routine (2 x 10, quick)")
        list += items([
            ("Body Blade", "Controlled reps."),
            ("Serratus Holds", "Controlled holds."),
            ("Plyo Ball Reverse Upward Tosses", "Controlled reps."),
            ("3-Way Banded Pull-Aparts", "Controlled reps."),
            ("Reverse L Wall Sits", "Controlled holds."),
            ("Glute Bridges", "Controlled reps."),
            ("Waterball Routine (optional)", "Full routine is in the wrap-up options.")
        ], group: "Activation")
        return RoutineStep(
            title: "Pre-Throw",
            subtitle: "Get the arm, shoulder, and hips ready before any throwing.",
            kind: .checklist(list))
    }()

    // Step 4b: intensive bullpen pre-throw (built in pieces to keep the compiler fast)
    static let preThrowBullpen: RoutineStep = {
        var list: [DrillItem] = []
        list += items([
            ("PVC Pass-Throughs", "2 x 10, wide grip, slow."),
            ("PVC Overhead Side Bends", "2 x 8 each side."),
            ("PVC Trunk Rotations", "2 x 10 each side.")
        ], group: "PVC Stretches")
        list += items([
            ("Arm Circles", "Forward and backward, 2 x 15 each."),
            ("Cross-Body Arm Swings", "2 x 10."),
            ("Scap Push-Ups", "2 x 10."),
            ("Wall Slides", "2 x 10.")
        ], group: "Arm Circles & Movement")
        list += items([
            ("J-Band External Rotation", "2 x 12 each arm."),
            ("J-Band Internal Rotation", "2 x 12 each arm."),
            ("J-Band Y's and T's", "2 x 10 each."),
            ("J-Band Pull-Aparts", "2 x 15."),
            ("J-Band Pronation / Supination", "2 x 12 each arm.")
        ], group: "J-Band")
        list += items([
            ("Forearm Flexors & Extensors", "Roll with a lacrosse ball. 45 sec each."),
            ("Biceps & Triceps Roll-Out", "Lacrosse ball against the wall. 30 sec each."),
            ("Wrist & Finger Stretches", "30 sec each direction.")
        ], group: "Forearm & Arm Roll-Out")
        return RoutineStep(
            title: "Pre-Throw (Bullpen)",
            subtitle: "A longer arm prep for bullpen days. About 12 minutes.",
            kind: .checklist(list))
    }()

    // Heavy day throwing
    static let longToss = RoutineStep(
        title: "Long Toss",
        subtitle: "Build out, then work back in. Stay athletic and let it fly on the way out.",
        kind: .checklist(items([
            ("Easy Throws, 60 ft", "10 throws, smooth."),
            ("Build to 90 ft", "10 throws, arc and rhythm."),
            ("Build to 120 ft", "10 throws."),
            ("Max Distance Block", "10-15 high-intent throws."),
            ("Work Back In", "10 throws from 90 ft down to 60 ft.")
        ])))

    // Bullpen step (interactive)
    static let bullpen = RoutineStep(
        title: "Bullpen",
        subtitle: "Pick a goal and follow the plan.",
        kind: .bullpen)

    // MARK: All routines

    static let all: [Routine] = [
        Routine(name: "Heavy Throw Day", dayType: .heavy, steps: [
            rollOut, staticStretch, dynamicWarmUp, preThrow,
            RoutineStep(title: "Plyo Ball Work",
                        subtitle: "Choose Plyo A (arm path) or Plyo B (light).",
                        kind: .plyos([PlyoLibrary.a, PlyoLibrary.b])),
            longToss
        ]),
        Routine(name: "Bullpen Day", dayType: .heavy, steps: [
            rollOut, staticStretch, dynamicWarmUp, preThrowBullpen,
            RoutineStep(title: "Plyo Ball Work",
                        subtitle: "Plyo C day: all A and B exercises.",
                        kind: .plyos([PlyoLibrary.c])),
            bullpen
        ]),
        Routine(name: "Recovery & Mobility", dayType: .recovery, steps: [
            rollOut, staticStretch, dynamicWarmUp, preThrow,
            RoutineStep(title: "Throwing",
                        subtitle: "Pick how you want to throw today.",
                        kind: .throwChoice(ThrowLibrary.options))
        ]),
        Routine(name: "Off Day Mobility", dayType: .off, steps: [
            rollOut, staticStretch
        ])
    ]
}

// MARK: - Recovery-day throwing options

enum ThrowLibrary {
    static let options: [ThrowOption] = [
        ThrowOption(
            name: "Plyos", icon: "figure.baseball",
            summary: "Half plyos, low intent, around 50%.",
            plyo: PlyoLibrary.half),
        ThrowOption(
            name: "Football Catch", icon: "football",
            summary: "40 throws total, easy to athletic.",
            blocks: items([
                ("Normal Throws", "20 throws, standard stance, easy to moderate effort."),
                ("Step-In Throws", "10 throws, step into each one with rhythm."),
                ("Athletic Throws", "10 throws on the move: on the run, off-platform, turn and throw.")
            ])),
        ThrowOption(
            name: "Light Baseball Catch", icon: "baseball",
            summary: "About 24 throws. Arc everything, nothing on a line.",
            blocks: items([
                ("Easy Warm-Up Throws", "8 throws at 40-45 ft."),
                ("Build to Max Distance", "10 arcing throws. Stay at or under your max distance."),
                ("Work Back In", "6 easy throws, coming back to 40-45 ft.")
            ]),
            hasDistance: true),
        ThrowOption(
            name: "No Throw", icon: "nosign",
            summary: "Skip throwing and move on to wrap-up.",
            isNoThrow: true)
    ]
}

// MARK: - Post-throw routines (from your sheets)

enum PostThrowLibrary {
    static let softTissue = DrillItem(
        name: "Soft Tissue Work",
        detail: "Lacrosse ball and foam roller on anything tight. Every day.")

    static let red: [DrillItem] = items([
        ("KB 90 Walks", "3 x 20 sec."),
        ("ITY Field Goal Step Back", "1-2 x 10 each."),
        ("Banded Wall Slides", "2 x 8."),
        ("Swimmers (Tennis Ball)", "2 x 8 each.")
    ])

    static let blue: [DrillItem] = items([
        ("Eccentric Landmines", "3 x 8."),
        ("Seated External Rotations", "2 x 8. Use 5/10 lbs."),
        ("Strength Manuals", "1 set."),
        ("KB Finger Tip Holds", "2 x 20 sec.")
    ])

    static let purple: [DrillItem] = items([
        ("Stability Manuals", "1 set."),
        ("Dead Hangs", "2 x 20-30 sec."),
        ("Over Shoulder Catch to Reverse Throws", "1 x 5 each. Black/Pink/Green."),
        ("Trampoline Tosses", "2 x 10.")
    ])

    static func exercises(for color: RecoveryColor) -> [DrillItem] {
        switch color {
        case .red: return red
        case .blue: return blue
        case .purple: return purple
        }
    }

    static let medBall: [DrillItem] = items([
        ("Shot Put", "2 x 6."),
        ("Hip Toss (Counter Movement)", "2 x 6."),
        ("Split Stance Overhead", "2 x 6."),
        ("Turn and Burns", "2 x 6."),
        ("Lying Drop Downs", "2 x 6."),
        ("Split Stance Seat Belts Reverse Throws", "2 x 6. Face away from the wall."),
        ("Pitching Seat Belts", "Rotational testing with 2 lb and 4 lb balls.")
    ])

    static let waterball: [DrillItem] = items([
        ("Overhead Side Hops", "1 x 20 sec."),
        ("Overhead Front/Back Hops", "1 x 20 sec."),
        ("Golf Swings", "1 x 20 sec."),
        ("Stick to Twist", "1 x 5."),
        ("RDLs", "1 x 5."),
        ("Side Hop Pitches", "1 x 5."),
        ("Forward Hops Pitches", "1 x 5."),
        ("Backward Hops Pitches", "1 x 5."),
        ("Drop Downs", "1 x 5."),
        ("Turn and Burns", "1 x 5.")
    ])
}
