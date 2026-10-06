import SwiftUI

/// Arm Lab logo. Uses the white-on-dark variant by default since the app runs in dark mode.
struct ArmLabLogo: View {
    enum Style { case full, mark }
    var style: Style = .full
    var height: CGFloat = 200

    var body: some View {
        Image(style == .full ? "LogoDark" : "LogoMarkDark")
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .accessibilityLabel("Arm Lab")
    }
}
