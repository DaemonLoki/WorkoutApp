import SwiftUI

extension View {
    /// The orange glow that pulses once behind a value that just Stepped Up (README §9 Motion). Each change of
    /// `trigger` plays it once; with Reduce Motion nothing pulses, since the new value already says it.
    public func stepUpGlow(trigger: some Equatable) -> some View {
        modifier(StepUpGlowModifier(trigger: trigger))
    }
}

private struct StepUpGlowModifier<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.phaseAnimator([false, true, false], trigger: trigger) { view, glows in
            view.shadow(color: .accentColor.opacity(glows && !reduceMotion ? 0.7 : 0), radius: glows ? 24 : 0)
        } animation: { glows in
            glows ? .easeOut(duration: 0.25) : .easeOut(duration: 0.6)
        }
    }
}
