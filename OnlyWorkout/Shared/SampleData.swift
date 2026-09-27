import Foundation
import OnlyWorkoutCore
import OnlyWorkoutStore
import SwiftData

/// Sample content for previews and UI tests.
enum SampleData {
    /// Adds a two-exercise "Push Day" Workout if there are no Workouts yet.
    @discardableResult
    static func insertStarterWorkout(into context: ModelContext) -> Workout? {
        let log = TrainingLog(context: context)
        guard log.workouts().isEmpty else { return nil }
        let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let bench = exercises.first { $0.catalogKey == "barbell-bench-press" }
        let pushdown = exercises.first { $0.catalogKey == "triceps-pushdown" }

        let workout = log.addWorkout(named: "Push Day")
        if let bench {
            let planned = log.add(bench, to: workout)
            planned.targetSets = 2
            planned.targetReps = 8
            planned.weight = 60
            planned.restSeconds = 30
        }
        if let pushdown {
            let planned = log.add(pushdown, to: workout)
            planned.targetSets = 1
            planned.targetReps = 12
            planned.weight = 25
        }
        try? context.save()
        return workout
    }

    /// An in-memory container with the catalog and a starter Workout, for previews.
    @MainActor
    static func previewContainer() -> ModelContainer {
        guard let container = try? StoreContainer.make(inMemory: true) else {
            fatalError("Preview store could not be created")
        }
        try? ExerciseCatalog.seed(into: container.mainContext)
        insertStarterWorkout(into: container.mainContext)
        return container
    }
}
