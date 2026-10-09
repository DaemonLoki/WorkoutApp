import Foundation
import OnlyWorkoutCore
import SwiftData

extension TrainingLog {
    /// Adds a Starter Rotation's Workouts at the end of the Rotation (README §7 Onboarding), with the weights
    /// entered per catalog key (missing = 0 kg). The same Exercise in several of its Workouts is linked (ADR-0006).
    @discardableResult
    public func add(
        _ rotation: StarterRotation, names: (Focus) -> String, weights: [String: Double], now: Date = .now
    ) -> [Workout] {
        let exercises = Dictionary(
            fetchAll(Exercise.self).compactMap { exercise in exercise.catalogKey.map { ($0, exercise) } },
            uniquingKeysWith: { first, _ in first })
        var firstPlanned: [String: PlannedExercise] = [:]
        return rotation.workouts.map { starter in
            let workout = addWorkout(named: names(starter.focus), now: now)
            var openSuperset: UUID?
            for item in starter.plannedExercises {
                guard let exercise = exercises[item.catalogKey] else { continue }
                let planned = add(exercise, to: workout, linkedTo: firstPlanned[item.catalogKey], now: now)
                planned.targetSets = item.sets
                planned.targetReps = item.reps
                planned.restSeconds = item.restSeconds
                planned.weight = weights[item.catalogKey] ?? 0
                if let id = openSuperset {
                    planned.supersetID = id
                    openSuperset = nil
                } else if item.supersetsWithNext {
                    let id = UUID()
                    planned.supersetID = id
                    openSuperset = id
                }
                firstPlanned[item.catalogKey] = firstPlanned[item.catalogKey] ?? planned
            }
            return workout
        }
    }
}
