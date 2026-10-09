import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftData
import SwiftUI

/// Home: waiting Step Ups, the Workout that's Next Up, and every other Workout one tap away.
struct TodayView: View {
    @Environment(AppModel.self) private var appModel
    @Query(Queries.liveWorkouts) private var workouts: [Workout]
    @Query(Queries.pendingSuggestions) private var suggestions: [ProgressionSuggestion]
    @Query(Queries.liveSessions) private var sessions: [Session]
    @State private var showsSettings = false
    @State private var newWorkout: Workout?

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    ContentUnavailableView {
                        Label(.noWorkoutsTitle, systemImage: "dumbbell")
                    } description: {
                        Text(.noWorkoutsMessage)
                    } actions: {
                        Button(.createWorkout) {
                            newWorkout = appModel.log.addWorkout(named: "")
                        }
                        .buttonStyle(.glassProminent)
                    }
                } else {
                    content
                }
            }
            .navigationTitle(Text(.tabToday))
            .onAppear {
                // Onboarding ended with Build My Own: open the new Workout's editor with its name still empty.
                if let workout = appModel.workoutToEdit {
                    appModel.workoutToEdit = nil
                    newWorkout = workout
                } else {
                    appModel.nameUnnamedWorkouts()
                }
            }
            .navigationDestination(item: $newWorkout) { workout in
                WorkoutEditorView(workout: workout)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(.settings, systemImage: "gearshape") { showsSettings = true }
                }
            }
            .sheet(isPresented: $showsSettings) {
                SettingsView()
            }
        }
    }

    private var nextUp: Workout? {
        let nextID = Rotation.nextUp(in: workouts.map(\.id), lastStarted: sessions.first?.workoutID)
        return workouts.first { $0.id == nextID }
    }

    private var content: some View {
        List {
            if !suggestions.isEmpty {
                ReadyToStepUpSection(suggestions: suggestions)
            }

            if let nextUp {
                Section {
                    NextUpCard(workout: nextUp) { appModel.requestStart(nextUp) }
                } header: {
                    Text(.nextUp)
                }
            }

            let others = workouts.filter { $0.id != nextUp?.id }
            if !others.isEmpty {
                Section {
                    ForEach(others) { workout in
                        Button {
                            appModel.requestStart(workout)
                        } label: {
                            LabeledContent {
                                Image(systemName: "play.fill").foregroundStyle(.tint)
                                    .accessibilityLabel(Text(.startSession))
                            } label: {
                                Text(workout.name)
                                Text(.exerciseCount(workout.orderedPlannedExercises.count))
                            }
                        }
                        .tint(.primary)
                    }
                } header: {
                    Text(.otherWorkouts)
                }
            }
        }
    }
}

#Preview {
    let container = SampleData.previewContainer()
    TodayView()
        .environment(AppModel(log: TrainingLog(context: container.mainContext)))
        .modelContainer(container)
}

#Preview("Ready to Step Up") {
    let container = SampleData.previewContainer()
    SampleData.insertPendingSuggestions(into: container.mainContext)
    return TodayView()
        .environment(AppModel(log: TrainingLog(context: container.mainContext)))
        .modelContainer(container)
}
