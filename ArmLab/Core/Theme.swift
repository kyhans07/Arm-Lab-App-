import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.30, green: 0.65, blue: 1.0)
    static let card = Color.white.opacity(0.08)

    static let backgroundTop = Color(red: 0.05, green: 0.09, blue: 0.20)
    static let backgroundBottom = Color(red: 0.02, green: 0.03, blue: 0.08)

    static let hero = LinearGradient(
        colors: [Color(red: 0.10, green: 0.55, blue: 0.95), Color(red: 0.38, green: 0.25, blue: 0.90)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Full-screen gradient that runs behind everything, including the safe areas.
struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [AppTheme.accent.opacity(0.25), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Hides default list/form backgrounds and applies the app gradient.
    func appScreen() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(AppBackground())
    }
}
