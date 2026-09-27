import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// The Workout to do next, with every Planned Exercise and a big Start button.
struct NextUpCard: View {
    let workout: Workout
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            Text(workout.name)
                .font(.title2.bold())

            if workout.orderedPlannedExercises.isEmpty {
                Text(.workoutHasNoExercises)
                    .foregroundStyle(.secondary)
            }
            ForEach(workout.orderedPlannedExercises) { planned in
                PlannedExerciseRow(planned: planned)
            }

            Button(action: onStart) {
                Text(.startSession).font(.headline).frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .disabled(workout.orderedPlannedExercises.isEmpty)
            .padding(.top, DesignTokens.Spacing.xs)
            .accessibilityIdentifier("startSessionButton")
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }
}
