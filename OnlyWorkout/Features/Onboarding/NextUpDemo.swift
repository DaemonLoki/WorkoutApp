import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// Tour page 1: Today with the Next Up card of a sample Push Day, with a Superset, arriving once.
struct NextUpDemo: View {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false

    /// Catalog Exercises with plausible Targets; Lateral Raise and Triceps Pushdown form a Superset.
    static let pushDay = [
        PlannedExerciseSummary(id: "bench", name: "Bench Press", target: Target(sets: 3, reps: 8, weight: 60)),
        PlannedExerciseSummary(id: "ohp", name: "Overhead Press", target: Target(sets: 3, reps: 8, weight: 40)),
        PlannedExerciseSummary(
            id: "incline", name: "Incline Dumbbell Press", target: Target(sets: 3, reps: 10, weight: 22)),
        PlannedExerciseSummary(
            id: "raise", name: "Lateral Raise", target: Target(sets: 2, reps: 12, weight: 8), isSuperset: true),
        PlannedExerciseSummary(
            id: "pushdown", name: "Triceps Pushdown", target: Target(sets: 2, reps: 12, weight: 25), isSuperset: true),
    ]

    var body: some View {
        DemoScreen(screen: Color(.systemGroupedBackground)) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(.tabToday)
                    .font(.largeTitle.bold())
                    .padding(.top, DesignTokens.Spacing.l)
                    .padding(.bottom, DesignTokens.Spacing.s)
                Text(.nextUp)
                    .font(.footnote.bold())
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.leading, DesignTokens.Spacing.m)
                // Like a row of Today's list: the card sits on the screen's grouped background.
                NextUpCard(name: String(localized: Focus.push.workoutName), plannedExercises: Self.pushDay) {}
                    .padding(DesignTokens.Spacing.m)
                    .background(
                        Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: DesignTokens.Radius.card)
                    )
                    .opacity(isShown ? 1 : 0)
                    .offset(y: isShown || reduceMotion ? 0 : DesignTokens.Spacing.l)
                    .scaleEffect(isShown || reduceMotion ? 1 : 0.96)
                Spacer(minLength: 0)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive, initial: true) {
            guard isActive, !isShown else { return }
            withAnimation(reduceMotion ? DesignTokens.Motion.reducedMotion : DesignTokens.Motion.entrance) {
                isShown = true
            }
        }
    }
}

#Preview {
    NextUpDemo(isActive: true)
        .padding()
}
