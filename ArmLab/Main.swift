import SwiftUI
import SwiftData

@main
struct ArmLabApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            DailyLog.self,
            WarmUpEntry.self,
            ThrowingLog.self,
            MoundLog.self,
            ExerciseLog.self
        ])
    }
}
