import OnlyWorkoutDesign
import SwiftUI

/// A fingertip for self-playing Welcome Tour demos: a soft circle that touches down on the Set view's Done button
/// and lifts off, so a Set logged by the demo reads as a tap. With Reduce Motion it only fades in and out.
struct TapIndicator: View {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Phase: CaseIterable {
        case away, down, lifted
    }

    var body: some View {
        Circle()
            // Always over the orange Done button, so white reads in light and dark.
            .fill(.white.opacity(0.35))
            .overlay { Circle().strokeBorder(.white.opacity(0.7), lineWidth: 1.5) }
            .shadow(color: .black.opacity(0.15), radius: 4)
            .frame(width: DesignTokens.Size.minimumTapTarget, height: DesignTokens.Size.minimumTapTarget)
            .phaseAnimator(Phase.allCases, trigger: trigger) { view, phase in
                view
                    .opacity(phase == .down ? 1 : 0)
                    .scaleEffect(reduceMotion ? 1 : scale(phase))
            } animation: { phase in
                phase == .down ? .easeOut(duration: DesignTokens.Motion.demoTapLanding) : .easeOut(duration: 0.3)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func scale(_ phase: Phase) -> Double {
        switch phase {
        case .away: 1.4
        case .down: 1
        case .lifted: 0.8
        }
    }
}

extension View {
    /// Shows a `TapIndicator` on the Done button inside this view each time `trigger` changes.
    func tapIndicatorOnDone(trigger: Int) -> some View {
        overlayPreferenceValue(DoneButtonAnchorKey.self) { anchor in
            GeometryReader { proxy in
                if let anchor {
                    TapIndicator(trigger: trigger)
                        .position(x: proxy[anchor].midX, y: proxy[anchor].midY)
                }
            }
        }
    }
}
