import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// The whole Session at a glance: skip, do later, add a Set, or correct a logged one.
struct SessionOverviewSheet: View {
    let session: any SessionDriver
    @Environment(\.dismiss) private var dismiss
    @State private var editing: EditedSet?

    struct EditedSet: Identifiable {
        let exerciseID: UUID
        let index: Int
        let set: LoggedSet
        var id: String { "\(exerciseID)-\(index)" }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(session.engine.exercises) { exercise in
                    Section {
                        ForEach(exercise.sets.indices, id: \.self) { index in
                            let set = exercise.sets[index]
                            Button {
                                editing = EditedSet(exerciseID: exercise.id, index: index, set: set)
                            } label: {
                                LabeledContent {
                                    Text(.repsAtWeight(set.reps, set.weight.kilograms)).monospacedDigit()
                                } label: {
                                    Text(set.isExtra ? .extraSet : .setNumber(index + 1))
                                }
                            }
                            .tint(.primary)
                        }
                        actions(for: exercise)
                    } header: {
                        HStack {
                            Text(exercise.name)
                            Spacer()
                            Text(statusText(exercise.status))
                        }
                    }
                }
            }
            .navigationTitle(Text(.sessionOverview))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.close, systemImage: "checkmark") { dismiss() }
                }
            }
            .sheet(item: $editing) { edited in
                SetEditorSheet(set: edited.set) { reps, weight in
                    session.editSet(exerciseID: edited.exerciseID, at: edited.index, reps: reps, weight: weight)
                }
            }
        }
    }

    @ViewBuilder
    private func actions(for exercise: SessionEngine.Exercise) -> some View {
        if exercise.status == .pending {
            Button(.doLater, systemImage: "arrow.uturn.down") { session.doLater(exercise.id) }
            Button(.skipExercise, systemImage: "forward") { session.skip(exercise.id) }
        }
        Button(.addSet, systemImage: "plus") { session.addExtraSet(exercise.id) }
    }

    private func statusText(_ status: SessionExerciseStatus) -> LocalizedStringResource {
        switch status {
        case .pending: .statusPending
        case .done: .statusDone
        case .skipped: .statusSkipped
        }
    }
}
