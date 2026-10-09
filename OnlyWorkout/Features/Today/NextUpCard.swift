import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// The Workout to do next, with every Planned Exercise and a big Start button.
struct NextUpCard: View {
    let name: String
    let plannedExercises: [PlannedExerciseSummary]
    let onStart: () -> Void

    init(name: String, plannedExercises: [PlannedExerciseSummary], onStart: @escaping () -> Void) {
        self.name = name
        self.plannedExercises = plannedExercises
        self.onStart = onStart
    }

    init(workout: Workout, onStart: @escaping () -> Void) {
        self.init(
            name: workout.name, plannedExercises: workout.orderedPlannedExercises.map(PlannedExerciseSummary.init),
            onStart: onStart)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            Text(name)
                .font(.title2.bold())

            if plannedExercises.isEmpty {
                Text(.workoutHasNoExercises)
                    .foregroundStyle(.secondary)
            }
            ForEach(plannedExercises) { planned in
                PlannedExerciseRow(summary: planned)
            }

            Button(action: onStart) {
                Text(.startSession).font(.headline).frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .disabled(plannedExercises.isEmpty)
            .padding(.top, DesignTokens.Spacing.xs)
            .accessibilityIdentifier("startSessionButton")
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }
}
