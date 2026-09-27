import OnlyWorkoutCore
import OnlyWorkoutStore
import SwiftData
import SwiftUI

/// The Exercise Catalog plus Custom Exercises. Browses, or picks one when `onPick` is set.
struct ExerciseLibraryView: View {
    var onPick: ((Exercise) -> Void)?
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @Query(Queries.liveExercises) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var muscleGroup: MuscleGroup?
    @State private var editing: Exercise?
    @State private var createsExercise = false

    var body: some View {
        List(filtered) { exercise in
            Button {
                if let onPick {
                    onPick(exercise)
                } else if exercise.isCustom {
                    editing = exercise
                }
            } label: {
                VStack(alignment: .leading) {
                    Text(exercise.name)
                    Text(exercise.muscleGroups.joinedTitles)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.primary)
            .swipeActions {
                if exercise.isCustom {
                    Button(.delete, systemImage: "trash", role: .destructive) { appModel.log.delete(exercise) }
                }
            }
        }
        .overlay {
            if filtered.isEmpty { ContentUnavailableView.search }
        }
        .searchable(text: $searchText)
        .navigationTitle(Text(onPick == nil ? .exercises : .addExercise))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if onPick != nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.cancel, systemImage: "xmark") { dismiss() }
                }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Picker(selection: $muscleGroup) {
                        Text(.allMuscleGroups).tag(MuscleGroup?.none)
                        ForEach(MuscleGroup.allCases) { group in
                            Text(group.title).tag(MuscleGroup?.some(group))
                        }
                    } label: {
                        Text(.muscleGroup)
                    }
                } label: {
                    Label(
                        .muscleGroup,
                        systemImage: muscleGroup == nil
                            ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
                Button(.newExercise, systemImage: "plus") { createsExercise = true }
            }
        }
        .sheet(item: $editing) { exercise in
            ExerciseEditorView(exercise: exercise)
        }
        .sheet(isPresented: $createsExercise) {
            ExerciseEditorView(exercise: nil) { created in
                onPick?(created)
            }
        }
    }

    private var filtered: [Exercise] {
        exercises.filter { exercise in
            (searchText.isEmpty || exercise.name.localizedStandardContains(searchText))
                && (muscleGroup.map { exercise.muscleGroups.contains($0) } ?? true)
        }
    }
}
