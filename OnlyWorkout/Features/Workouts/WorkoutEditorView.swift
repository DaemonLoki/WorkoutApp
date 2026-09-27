import OnlyWorkoutStore
import SwiftData
import SwiftUI

/// Edits a Workout: its name, its Planned Exercises, their order and Supersets.
struct WorkoutEditorView: View {
    @Bindable var workout: Workout
    @Environment(AppModel.self) private var appModel
    @Query(Queries.pendingSuggestions) private var suggestions: [ProgressionSuggestion]
    @State private var showsPicker = false
    @State private var newlyAdded: PlannedExercise?

    var body: some View {
        let planned = workout.orderedPlannedExercises
        List {
            Section {
                TextField(text: $workout.name) { Text(.workoutName) }
                    .font(.headline)
            }
            Section {
                ForEach(planned) { item in
                    NavigationLink(value: item) {
                        PlannedExerciseRow(
                            planned: item,
                            hasPendingSuggestion: suggestions.contains { $0.plannedExerciseID == item.id })
                    }
                    .contextMenu { supersetMenu(for: item, in: planned) }
                }
                .onMove { source, destination in move(planned, from: source, to: destination) }
                .onDelete { offsets in
                    for index in offsets { appModel.log.delete(planned[index]) }
                }
                Button(.addExercise, systemImage: "plus") { showsPicker = true }
            } header: {
                Text(.exercises)
            } footer: {
                Text(.supersetHint)
            }
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .onChange(of: workout.name) { workout.updatedAt = .now }
        .navigationDestination(for: PlannedExercise.self) { item in
            PlannedExerciseEditorView(planned: item)
        }
        .navigationDestination(item: $newlyAdded) { item in
            PlannedExerciseEditorView(planned: item)
        }
        .sheet(isPresented: $showsPicker) {
            NavigationStack {
                ExerciseLibraryView { exercise in
                    showsPicker = false
                    newlyAdded = appModel.log.add(exercise, to: workout)
                }
            }
        }
    }

    @ViewBuilder
    private func supersetMenu(for item: PlannedExercise, in planned: [PlannedExercise]) -> some View {
        if item.supersetID != nil {
            Button(.breakSuperset, systemImage: "link.badge.minus") {
                appModel.log.supersetPartner(of: item)?.supersetID = nil
                item.supersetID = nil
                workout.updatedAt = .now
            }
        } else if let index = planned.firstIndex(of: item), index + 1 < planned.count,
            planned[index + 1].supersetID == nil
        {
            Button(.supersetWithNext, systemImage: "link") {
                let id = UUID()
                item.supersetID = id
                planned[index + 1].supersetID = id
                workout.updatedAt = .now
            }
        }
    }

    /// Reorders and dissolves any Superset whose halves are no longer next to each other.
    private func move(_ planned: [PlannedExercise], from source: IndexSet, to destination: Int) {
        var reordered = planned
        reordered.move(fromOffsets: source, toOffset: destination)
        let now = Date.now
        for (index, item) in reordered.enumerated() {
            if item.position != index {
                item.position = index
                item.updatedAt = now
            }
        }
        for (index, item) in reordered.enumerated() {
            guard let id = item.supersetID else { continue }
            let neighbours = [index - 1, index + 1].filter(reordered.indices.contains).map { reordered[$0] }
            if !neighbours.contains(where: { $0.supersetID == id }) {
                item.supersetID = nil
                item.updatedAt = now
            }
        }
        workout.updatedAt = now
    }
}
