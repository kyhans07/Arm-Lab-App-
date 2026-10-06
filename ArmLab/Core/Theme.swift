import SwiftUI

enum AppTheme {
    /// Arm Lab brand palette (taken from the logo)
    static let navy = Color(red: 0.12, green: 0.21, blue: 0.38)
    static let brandRed = Color(red: 0.85, green: 0.26, blue: 0.28)
    static let accent = brandRed
    static let card = Color.white.opacity(0.08)

    static let backgroundTop = Color(red: 0.07, green: 0.12, blue: 0.25)
    static let backgroundBottom = Color(red: 0.02, green: 0.04, blue: 0.10)

    static let hero = LinearGradient(
        colors: [Color(red: 0.16, green: 0.29, blue: 0.52), Color(red: 0.07, green: 0.12, blue: 0.27)],
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
