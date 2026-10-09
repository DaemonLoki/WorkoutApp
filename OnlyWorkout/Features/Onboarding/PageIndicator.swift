import OnlyWorkoutDesign
import SwiftUI

/// Where the Welcome Tour is: one dot per page, the current one stretched into a pill. VoiceOver reads it as
/// "Page 2 of 5".
struct PageIndicator: View {
    let count: Int
    let current: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private static let dot = 8.0
    private static let currentWidth = 22.0

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? AnyShapeStyle(.primary) : AnyShapeStyle(.quaternary))
                    .frame(width: index == current ? Self.currentWidth : Self.dot, height: Self.dot)
            }
        }
        .animation(reduceMotion ? DesignTokens.Motion.reducedMotion : DesignTokens.Motion.valueChange, value: current)
        .accessibilityElement()
        .accessibilityLabel(Text(.pageIndicator(current + 1, count)))
    }
}
