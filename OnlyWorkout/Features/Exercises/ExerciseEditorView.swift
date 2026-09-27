import OnlyWorkoutCore
import OnlyWorkoutStore
import SwiftData
import SwiftUI

/// Creates or edits a Custom Exercise.
struct ExerciseEditorView: View {
    let exercise: Exercise?
    var onCreate: ((Exercise) -> Void)?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var equipment: Equipment
    @State private var muscleGroups: Set<MuscleGroup>

    init(exercise: Exercise?, onCreate: ((Exercise) -> Void)? = nil) {
        self.exercise = exercise
        self.onCreate = onCreate
        _name = State(initialValue: exercise?.name ?? "")
        _equipment = State(initialValue: exercise?.equipment ?? .machine)
        _muscleGroups = State(initialValue: Set(exercise?.muscleGroups ?? []))
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(text: $name) { Text(.exerciseName) }
                Picker(selection: $equipment) {
                    ForEach(Equipment.allCases) { Text($0.title).tag($0) }
                } label: {
                    Text(.equipment)
                }
                Section {
                    ForEach(MuscleGroup.allCases) { group in
                        Button {
                            if muscleGroups.contains(group) {
                                muscleGroups.remove(group)
                            } else {
                                muscleGroups.insert(group)
                            }
                        } label: {
                            LabeledContent {
                                if muscleGroups.contains(group) {
                                    Image(systemName: "checkmark").foregroundStyle(.tint)
                                }
                            } label: {
                                Text(group.title)
                            }
                        }
                        .tint(.primary)
                    }
                } header: {
                    Text(.muscleGroups)
                }
            }
            .navigationTitle(Text(exercise == nil ? .newExercise : .editExercise))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.cancel, systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.save, systemImage: "checkmark", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || muscleGroups.isEmpty)
                }
            }
        }
    }

    private func save() {
        let ordered = MuscleGroup.allCases.filter(muscleGroups.contains)
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let exercise {
            exercise.name = trimmed
            exercise.equipment = equipment
            exercise.muscleGroups = ordered
            exercise.updatedAt = .now
        } else {
            let created = Exercise(name: trimmed, equipment: equipment, muscleGroups: ordered)
            modelContext.insert(created)
            onCreate?(created)
        }
        try? modelContext.save()
        dismiss()
    }
}
