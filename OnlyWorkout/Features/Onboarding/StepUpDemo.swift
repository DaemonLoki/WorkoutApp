import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// Tour page 3: after a Target Hit the real Step Up card slides in. Accepting rolls the weight from 60 to 62.5 kg
/// (or the reps from 8 to 9) with the orange glow; waiting a moment accepts the weight by itself, without a haptic.
struct StepUpDemo: View {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsOffer = false
    @State private var target = Self.start
    @State private var stepUps = 0
    @State private var tappedStepUps = 0

    private static let start = Target(sets: 3, reps: 8, weight: 60)
    private static let offer = SessionOffer(
        id: UUID(), exerciseID: UUID(), exerciseName: "Bench Press",
        suggestion: WeightSuggestion(
            kind: .stepUp, reason: .targetHit, fromWeight: 60, toWeight: 62.5, fromReps: 8, toReps: 9))

    var body: some View {
        DemoScreen {
            VStack(spacing: DesignTokens.Spacing.l) {
                Spacer(minLength: 0)
                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text(verbatim: "Bench Press")
                        .font(.largeTitle.bold())
                    Text(.target)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: DesignTokens.Spacing.xxs) {
                    BigNumberText(target.weight, text: target.weight.weightNumber)
                        .foregroundStyle(stepUps > 0 ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                        .stepUpGlow(trigger: stepUps)
                    Text(.weightKg)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(target.setsAndReps)
                    .font(.title2.bold())
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(target.reps)))
                    .animation(DesignTokens.Motion.valueChange, value: target.reps)
                if stepUps > 0 {
                    Label {
                        Text(change)
                    } icon: {
                        Image(systemName: "arrow.up.circle.fill").foregroundStyle(.tint)
                    }
                    .font(.headline)
                    .transition(.opacity)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .safeAreaInset(edge: .bottom) {
                if showsOffer {
                    OfferCard(offer: Self.offer, prefersReps: false) { accept, change in
                        if accept { tappedStepUps += 1 }
                        answer(accept: accept, change: change)
                    }
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? DesignTokens.Motion.reducedMotion : DesignTokens.Motion.card, value: showsOffer)
        }
        .sensoryFeedback(.success, trigger: tappedStepUps)
        .task(id: isActive) {
            guard isActive else {
                showsOffer = false
                target = Self.start
                stepUps = 0
                return
            }
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled else { return }
            showsOffer = true
            try? await Task.sleep(for: .seconds(DesignTokens.Motion.demoIdle + 1))
            guard !Task.isCancelled, showsOffer else { return }
            answer(accept: true, change: .weight)
        }
    }

    /// "60 → 62.5 kg" or "8 → 9 reps", once Stepped Up.
    private var change: LocalizedStringResource {
        target.reps != Self.start.reps
            ? .tourStepUpChangeReps(Self.start.reps, target.reps)
            : .tourStepUpChange(Self.start.weight.weightNumber, target.weight.kilograms)
    }

    private func answer(accept: Bool, change: WeightSuggestion.Change?) {
        showsOffer = false
        guard accept, let change else { return }
        switch change {
        case .weight: target.weight = Self.offer.suggestion.toWeight
        case .reps: target.reps = Self.offer.suggestion.toReps
        }
        withAnimation(reduceMotion ? DesignTokens.Motion.reducedMotion : DesignTokens.Motion.card) { stepUps += 1 }
    }
}

#Preview {
    StepUpDemo(isActive: true)
        .padding()
}
