import OnlyWorkoutDesign
import SwiftUI

/// Press feedback for custom tappable surfaces: scales to 0.97 on touch-down (README §9 Motion).
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DesignTokens.Motion.valueChange, value: configuration.isPressed)
    }
}
