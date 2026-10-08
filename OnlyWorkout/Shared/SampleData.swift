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

    /// A pending Step Up and a pending Step Down for the starter Workout's Planned Exercises.
    static func insertPendingSuggestions(into context: ModelContext) {
        let log = TrainingLog(context: context)
        let planned = log.workouts().first?.orderedPlannedExercises ?? []
        if let bench = planned.first {
            log.offer(
                WeightSuggestion(
                    kind: .stepUp, reason: .targetHit, fromWeight: bench.weight, toWeight: bench.weight + 2.5),
                for: bench.id, from: nil)
        }
        if planned.count > 1 {
            let pushdown = planned[1]
            log.offer(
                WeightSuggestion(
                    kind: .stepDown, reason: .stall, fromWeight: pushdown.weight, toWeight: pushdown.weight - 2.5),
                for: pushdown.id, from: nil)
        }
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
