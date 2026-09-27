import OnlyWorkoutStore
import SwiftData
import SwiftUI

/// The Rotation: Workouts in the order they come up. Drag to reorder.
struct WorkoutsView: View {
    @Environment(AppModel.self) private var appModel
    @Query(Queries.liveWorkouts) private var workouts: [Workout]
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(workouts) { workout in
                    NavigationLink(value: workout) {
                        VStack(alignment: .leading) {
                            Text(workout.name)
                            Text(.exerciseCount(workout.orderedPlannedExercises.count))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onMove(perform: move)
                .onDelete { offsets in
                    for index in offsets { appModel.log.delete(workouts[index]) }
                }
            }
            .overlay {
                if workouts.isEmpty {
                    ContentUnavailableView {
                        Label(.noWorkoutsTitle, systemImage: "dumbbell")
                    } description: {
                        Text(.noWorkoutsMessage)
                    }
                }
            }
            .navigationTitle(Text(.tabWorkouts))
            .navigationDestination(for: Workout.self) { workout in
                WorkoutEditorView(workout: workout)
            }
            .navigationDestination(for: ExerciseLibraryRoute.self) { _ in
                ExerciseLibraryView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(value: ExerciseLibraryRoute()) {
                        Label(.exercises, systemImage: "books.vertical")
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    EditButton()
                    Button(.createWorkout, systemImage: "plus") {
                        path.append(appModel.log.addWorkout(named: String(localized: .newWorkoutName)))
                    }
                }
            }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = workouts
        reordered.move(fromOffsets: source, toOffset: destination)
        appModel.log.reorder(reordered)
    }
}

/// Navigation value for the Exercise Catalog screen.
struct ExerciseLibraryRoute: Hashable {}
