import SwiftUI
import SwiftData

// MARK: - Models

enum ThrowingHand: String, CaseIterable { case right = "Right", left = "Left" }

enum ThrowingPhase: String, CaseIterable {
    case offSeason = "Off-Season", preSeason = "Pre-Season", inSeason = "In-Season", recovery = "Recovery"
}

enum DayType: String, CaseIterable {
    case off = "Off Day: No Throw"
    case lightRecovery = "Light Day: Recovery & Mobility"
    case lightCatch = "Light Day: Catch & Drill Work"
    case heavyPlyo = "Heavy Day: Plyo Ball Only"
    case heavyLongToss = "Heavy Day: Long Toss"
    case heavyBullpen = "Heavy Day: Bullpen"
    case live = "Live"

    var icon: String {
        switch self {
        case .off: return "bed.double.fill"
        case .lightRecovery: return "figure.cooldown"
        case .lightCatch: return "figure.baseball"
        case .heavyPlyo: return "bolt.fill"
        case .heavyLongToss: return "arrow.up.right.circle.fill"
        case .heavyBullpen: return "scope"
        case .live: return "flame.fill"
        }
    }

    /// Live is selectable only and is never recommended by the quiz or the schedule.
    var canBeRecommended: Bool { self != .live }
}

// MARK: - Root (Entry & Auth gating)

struct RootView: View {
    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        Group {
            if !isSignedIn {
                SignInView()
            } else if !hasOnboarded {
                OnboardingView()
            } else {
                DashboardView()
            }
        }
        .preferredColorScheme(.dark)
        .tint(AppTheme.accent)
    }
}

// MARK: - 1. Landing / Sign-In (local stub; swap for real auth later)

// MARK: - 1b. Onboarding

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("throwingHand") private var hand = ThrowingHand.right.rawValue
    @AppStorage("throwingPhase") private var phase = ThrowingPhase.inSeason.rawValue
    @AppStorage("throwDaysPerWeek") private var throwDays = 4

    var body: some View {
        NavigationStack {
            Form {
                Picker("Throwing Hand", selection: $hand) {
                    ForEach(ThrowingHand.allCases, id: \.rawValue) { Text($0.rawValue).tag($0.rawValue) }
                }
                Picker("Active Phase", selection: $phase) {
                    ForEach(ThrowingPhase.allCases, id: \.rawValue) { Text($0.rawValue).tag($0.rawValue) }
                }
                Stepper("Throw days per week: \(throwDays)", value: $throwDays, in: 1...7)

                Button("Finish Setup") { hasOnboarded = true }
                    .bold()
            }
            .appScreen()
            .navigationTitle("Set Up Profile")
        }
    }
}

// MARK: - 2. Main Dashboard

struct NavCard: View {
    let title: String
    let icon: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title2).frame(width: 36).foregroundColor(AppTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.card))
    }
}

// MARK: - Node 1: Direct Routine Selection

struct RoutineListView: View {
    let onStart: (Routine) -> Void

    var body: some View {
        List(RoutineLibrary.all) { routine in
            Button { onStart(routine) } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name).font(.headline)
                    Text("\(routine.steps.count) steps")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .appScreen()
            .navigationTitle("Routines")
    }
}

// MARK: - Node 2: Guided Quiz

struct QuizView: View {
    let onStart: (Routine) -> Void

    @AppStorage("quizRecommendation") private var savedPick = ""

    @State private var armFeel = 4.0       // 1 = bad, 5 = great
    @State private var fatigue = 3.0       // 1 = fresh, 10 = wrecked
    @State private var daysToOuting = 3
    @State private var exertion = 3.0      // 1 = light, 5 = max
    @State private var resultType: DayType?
    @State private var resultReason = ""

    private func recommend() -> (DayType, String) {
        if armFeel <= 1 && fatigue >= 9 {
            return (.off, "Your arm is telling you it needs rest. Take the day off and reassess tomorrow.")
        }
        if armFeel <= 2 || fatigue >= 8 {
            return (.lightRecovery, "Low arm feel and high fatigue point to an easy day. Mobility work helps you bounce back.")
        }
        if daysToOuting <= 1 {
            return (.lightRecovery, "With an outing coming up, keep today light so you're fresh when it counts.")
        }
        switch Int(exertion) {
        case 1, 2:
            return (.lightCatch, "You want it easy. Catch and drill work keeps the arm moving without much load.")
        case 3:
            return (.heavyPlyo, "Your arm feels good. Plyo work builds arm care and intent without baseball throws.")
        case 4:
            return (.heavyLongToss, "You feel good and want to push. A long toss day builds arm speed and distance.")
        default:
            return (.heavyBullpen, "You feel great and want max work. A bullpen day lets you train off the mound.")
        }
    }

    var body: some View {
        Form {
            Section {
                Text("Answer four quick questions and we'll match you to the right day.")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            Section("How does your arm feel? \(Int(armFeel))/5") {
                Slider(value: $armFeel, in: 1...5, step: 1)
            }
            Section("Fatigue level: \(Int(fatigue))/10") {
                Slider(value: $fatigue, in: 1...10, step: 1)
            }
            Section("Upcoming outing") {
                Stepper("Days until outing: \(daysToOuting)", value: $daysToOuting, in: 0...10)
            }
            Section("Desired exertion: \(Int(exertion))/5") {
                Slider(value: $exertion, in: 1...5, step: 1)
            }
            Section {
                Button {
                    let (type, reason) = recommend()
                    resultType = type
                    resultReason = reason
                    savedPick = type.rawValue
                } label: {
                    Label("Get My Recommendation", systemImage: "sparkles").bold()
                }
            }

            if let resultType {
                Section("Recommended for you") {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(resultType.rawValue, systemImage: resultType.icon)
                            .font(.headline).foregroundColor(AppTheme.accent)
                        Text(resultReason).font(.subheadline)
                    }
                    ForEach(RoutineLibrary.all.filter { $0.dayType == resultType }) { routine in
                        Button("Start \(routine.name)") { onStart(routine) }
                    }
                }
                Section("Other options") {
                    ForEach(RoutineLibrary.all.filter { $0.dayType != resultType }) { routine in
                        Button {
                            onStart(routine)
                        } label: {
                            HStack {
                                Image(systemName: routine.dayType.icon).frame(width: 28)
                                VStack(alignment: .leading) {
                                    Text(routine.name)
                                    Text("\(routine.steps.count) steps").font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .appScreen()
            .navigationTitle("Routine Quiz")
    }
}

// MARK: - Node 3: Progress & Log History

struct HistoryView: View {
    @Query(sort: \DailyLog.date, order: .reverse) private var logs: [DailyLog]

    var body: some View {
        List {
            if logs.isEmpty {
                Text("No logs yet. Finish a routine to see it here.")
                    .foregroundColor(.secondary)
            }
            ForEach(logs) { log in
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.date.formatted(date: .abbreviated, time: .omitted)).font(.headline)
                    Text("Readiness \(log.readinessScore)/10 · Focus \(log.mentalFocusScore)/10")
                        .font(.caption).foregroundColor(.secondary)
                    if !log.notes.isEmpty {
                        Text(log.notes).font(.caption)
                    }
                }
            }
        }
        .appScreen()
            .navigationTitle("History")
    }
}

// MARK: - Node 4: Settings & Profile

struct SettingsView: View {
    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("throwingHand") private var hand = ThrowingHand.right.rawValue
    @AppStorage("throwingPhase") private var phase = ThrowingPhase.inSeason.rawValue
    @AppStorage("throwDaysPerWeek") private var throwDays = 4
    @AppStorage("notificationsOn") private var notificationsOn = true

    var body: some View {
        Form {
            Section("Profile") {
                LabeledContent("Email", value: userEmail)
                Picker("Hand", selection: $hand) {
                    ForEach(ThrowingHand.allCases, id: \.rawValue) { Text($0.rawValue).tag($0.rawValue) }
                }
                Picker("Phase", selection: $phase) {
                    ForEach(ThrowingPhase.allCases, id: \.rawValue) { Text($0.rawValue).tag($0.rawValue) }
                }
                Stepper("Throw days per week: \(throwDays)", value: $throwDays, in: 1...7)
            }
            Section("Preferences") {
                Toggle("Notifications", isOn: $notificationsOn)
            }
            Section {
                Button("Redo Onboarding") { hasOnboarded = false }
                Button("Sign Out", role: .destructive) { isSignedIn = false }
            }
        }
        .appScreen()
            .navigationTitle("Settings")
    }
}

// MARK: - 3. Routine Execution Flow

// MARK: - Shared schedule helper (placeholder: replace with onboarding schedule)

func scheduledDayType(for date: Date) -> DayType {
    switch Calendar.current.component(.weekday, from: date) { // 1 = Sunday
    case 2:  return .heavyLongToss
    case 3:  return .lightRecovery
    case 4:  return .heavyBullpen
    case 5:  return .lightCatch
    case 6:  return .heavyPlyo
    default: return .off
    }
}

// MARK: - Landing Page

enum AuthMode: String, Identifiable {
    case login, register
    var id: String { rawValue }
}

struct SignInView: View {
    @State private var authMode: AuthMode?

    var body: some View {
        ZStack {
            AppTheme.hero
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Spacer()
                Image(systemName: "figure.baseball")
                    .font(.system(size: 84))
                    .foregroundColor(.white)
                Text("ArmLab")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Train smarter. Protect your arm.")
                    .foregroundColor(.white.opacity(0.85))
                Spacer()

                Button { authMode = .register } label: {
                    Text("Create Account")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(AppTheme.accent)
                        .cornerRadius(14)
                }

                Button { authMode = .login } label: {
                    Text("Log In")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white, lineWidth: 2))
                }
            }
            .padding(24)
        }
        .sheet(item: $authMode) { mode in
            AuthFormView(mode: mode)
        }
    }
}

struct AuthFormView: View {
    let mode: AuthMode

    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("userName") private var userName = ""
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                if mode == .register {
                    TextField("First name", text: $name)
                }
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)

                Button(mode == .register ? "Create Account" : "Log In") {
                    userEmail = email
                    if mode == .register { userName = name }
                    isSignedIn = true
                }
                .bold()
                .disabled(email.isEmpty || password.isEmpty)
            }
            .appScreen()
            .navigationTitle(mode == .register ? "Register" : "Welcome Back")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Dashboard

struct DashboardView: View {
    @Query(sort: \DailyLog.date, order: .reverse) private var logs: [DailyLog]
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""

    @AppStorage("quizRecommendation") private var quizPick = ""

    @State private var runningRoutine: Routine?
    @State private var showQuickLog = false

    private let calendar = Calendar.current

    private var firstName: String {
        if !userName.isEmpty { return userName }
        return userEmail.split(separator: "@").first.map(String.init) ?? "Pitcher"
    }

    private var todayType: DayType { scheduledDayType(for: Date()) }

    private var todaysRoutine: Routine? {
        RoutineLibrary.all.first { $0.dayType == todayType }
    }

    private var startOfWeek: Date {
        calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    }

    private var weekLogs: [DailyLog] { logs.filter { $0.date >= startOfWeek } }

    private var avgReadiness: String {
        guard !weekLogs.isEmpty else { return "--" }
        let avg = Double(weekLogs.map(\.readinessScore).reduce(0, +)) / Double(weekLogs.count)
        return String(format: "%.1f", avg)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Hi, \(firstName)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))

                    todayCard
                    elseSection
                    weekStrip

                    HStack(spacing: 12) {
                        StatTile(title: "Sessions this week", value: "\(weekLogs.count)", icon: "flame.fill")
                        StatTile(title: "Avg readiness", value: avgReadiness, icon: "bolt.heart.fill")
                    }

                    if let last = logs.first {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Last Session").font(.headline)
                            Text(last.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline).foregroundColor(.secondary)
                            if !last.notes.isEmpty {
                                Text(last.notes).font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        NavigationLink { RoutineListView(onStart: { runningRoutine = $0 }) } label: {
                            NavTile(title: "Routines", icon: "list.bullet.rectangle")
                        }
                        NavigationLink { QuizView(onStart: { runningRoutine = $0 }) } label: {
                            NavTile(title: "Routine Quiz", icon: "questionmark.bubble")
                        }
                        NavigationLink { HistoryView() } label: {
                            NavTile(title: "Progress", icon: "chart.line.uptrend.xyaxis")
                        }
                        NavigationLink { SettingsView() } label: {
                            NavTile(title: "Settings", icon: "gearshape")
                        }
                    }

                    Button("Open Detailed Training Log") { showQuickLog = true }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .buttonStyle(.plain)
            .appScreen()
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(item: $runningRoutine) { routine in
            ExecutionFlowView(routine: routine)
        }
        .sheet(isPresented: $showQuickLog) { TrainingLogView() }
    }

    // "Looking for something else?" + quiz prompt + alternative days
    private var otherRoutines: [Routine] {
        RoutineLibrary.all.filter { $0.id != todaysRoutine?.id }
    }

    private var elseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Looking for something else?")
                    .font(.title3).bold()
                Text("Tell us how your arm feels and we'll recommend the right day.")
                    .font(.subheadline).foregroundColor(.secondary)
            }

            NavigationLink {
                QuizView(onStart: { runningRoutine = $0 })
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.blue))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Take the routine quiz").font(.headline)
                        Text(quizPick.isEmpty ? "Takes about 30 seconds" : "Last pick: \(quizPick)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue.opacity(0.12)))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(otherRoutines) { routine in
                        Button { runningRoutine = routine } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: routine.dayType.icon)
                                    .font(.title3).foregroundColor(AppTheme.accent)
                                Text(routine.name).font(.subheadline).bold()
                                Text("\(routine.steps.count) steps")
                                    .font(.caption).foregroundColor(.secondary)
                                if quizPick == routine.dayType.rawValue {
                                    Text("Recommended")
                                        .font(.caption2).bold()
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Capsule().fill(Color.blue))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: 150, alignment: .leading)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.card))
                        }
                    }
                }
            }
        }
    }

    // Today's status
    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            Label(todayType.rawValue, systemImage: todayType.icon)
                .font(.title2).bold()
                .foregroundColor(.white)
            if let routine = todaysRoutine {
                Button { runningRoutine = routine } label: {
                    Text("Start \(routine.name)")
                        .bold()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .foregroundColor(AppTheme.accent)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            AppTheme.hero
        )
        .cornerRadius(18)
    }

    // Week at a glance
    private var weekStrip: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) ?? Date()
                let isToday = calendar.isDateInToday(date)
                let done = logs.contains { calendar.isDate($0.date, inSameDayAs: date) }

                VStack(spacing: 6) {
                    Text(date.formatted(.dateTime.weekday(.narrow)))
                        .font(.caption2).foregroundColor(.secondary)
                    Image(systemName: done ? "checkmark.circle.fill" : scheduledDayType(for: date).icon)
                        .foregroundColor(done ? .green : (isToday ? .blue : .gray))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isToday ? Color.blue.opacity(0.15) : AppTheme.card)
                )
            }
        }
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundColor(AppTheme.accent)
            Text(value).font(.title).bold()
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
    }
}

struct NavTile: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title).foregroundColor(AppTheme.accent)
            Text(title).font(.subheadline).bold()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
    }
}
