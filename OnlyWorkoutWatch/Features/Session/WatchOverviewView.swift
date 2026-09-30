import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// The whole Session: skip, do later, add a Set, or end it.
struct WatchOverviewView: View {
    let runner: SessionRunner
    let onEnd: () -> Void
    @State private var confirmsEnd = false

    var body: some View {
        List {
            Button(.endSession, role: .destructive) {
                if runner.engine.isComplete { onEnd() } else { confirmsEnd = true }
            }
            ForEach(runner.engine.exercises) { exercise in
                Section {
                    if exercise.status == .pending {
                        Button(.doLater) { runner.doLater(exercise.id) }
                        Button(.skipExercise) { runner.skip(exercise.id) }
                    }
                    Button(.addSet) { runner.addExtraSet(exercise.id) }
                } header: {
                    Text(.watchExerciseProgress(exercise.name, exercise.sets.count, exercise.totalSets))
                }
            }
        }
        .confirmationDialog(Text(.endSessionEarlyTitle), isPresented: $confirmsEnd) {
            Button(.endSession, role: .destructive, action: onEnd)
        }
    }
}
