import SwiftUI

/// The Session-complete moment: a ring closes, then a checkmark draws in (README §9).
/// With Reduce Motion it simply fades in.
public struct CelebrationMark: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ringProgress = 0.0
    @State private var showsCheck = false

    public init() {}

    public var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(.tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: "checkmark")
                .font(.system(size: DesignTokens.Size.celebrationMark * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(.tint)
                .symbolEffect(.drawOn, isActive: !showsCheck)
        }
        .frame(width: DesignTokens.Size.celebrationMark, height: DesignTokens.Size.celebrationMark)
        .scaleEffect(showsCheck || reduceMotion ? 1 : 0.9)
        .sensoryFeedback(.success, trigger: showsCheck)
        .accessibilityHidden(true)
        .task {
            if reduceMotion {
                withAnimation(DesignTokens.Motion.reducedMotion) {
                    ringProgress = 1
                    showsCheck = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.45)) { ringProgress = 1 }
                try? await Task.sleep(for: .seconds(0.4))
                withAnimation(DesignTokens.Motion.celebration) { showsCheck = true }
            }
        }
    }
}
