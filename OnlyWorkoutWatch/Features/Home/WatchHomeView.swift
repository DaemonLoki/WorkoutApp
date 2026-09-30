import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// Next Up first, every other Workout below. Workouts are edited on the iPhone.
struct WatchHomeView: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        NavigationStack {
            let workouts = model.workouts
            List {
                if let nextUp = model.nextUp {
                    Section {
                        Button {
                            model.start(nextUp)
                        } label: {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                                Text(nextUp.name).font(.headline)
                                Text(.exerciseCount(nextUp.orderedPlannedExercises.count))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Label(.startSession, systemImage: "play.fill")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .disabled(nextUp.orderedPlannedExercises.isEmpty)
                    } header: {
                        Text(.nextUp)
                    }
                }
                let others = workouts.filter { $0.id != model.nextUp?.id }
                if !others.isEmpty {
                    Section {
                        ForEach(others) { workout in
                            Button(workout.name) { model.start(workout) }
                                .disabled(workout.orderedPlannedExercises.isEmpty)
                        }
                    } header: {
                        Text(.otherWorkouts)
                    }
                }
            }
            .overlay {
                if workouts.isEmpty {
                    ContentUnavailableView {
                        Label(.noWorkoutsTitle, systemImage: "dumbbell")
                    } description: {
                        Text(.watchNoWorkoutsMessage)
                    }
                }
            }
            .navigationTitle(Text(verbatim: "OnlyWorkout"))
        }
    }
}
