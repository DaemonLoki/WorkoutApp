import Foundation
import OnlyWorkoutCore
import SwiftData

/// An Exercise placed in a Workout with its own Target, Rest and Weight Step (see CONTEXT.md).
@Model
public final class PlannedExercise {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    /// The `updatedAt` the cloud is known to have; local only, never synced.
    public var syncedUpdatedAt: Date?

    public var workout: Workout?
    @Relationship(deleteRule: .nullify)
    public var exercise: Exercise?
    public var position: Int
    /// Shared by the two halves of a Superset.
    public var supersetID: UUID?
    /// Shared by Linked Planned Exercises: same Exercise in other Workouts, one Target (ADR-0006).
    public var linkID: UUID?
    public var targetSets: Int
    public var targetReps: Int
    /// Current Target weight in kg (Added Weight for bodyweight Exercises).
    public var weight: Double
    public var weightStep: Double
    public var restSeconds: Int

    public init(
        id: UUID = UUID(), exercise: Exercise, position: Int, targetSets: Int = PlanDefaults.targetSets,
        targetReps: Int = PlanDefaults.targetReps, weight: Double = 0, weightStep: Double? = nil,
        restSeconds: Int = PlanDefaults.restSeconds, now: Date = .now
    ) {
        self.id = id
        self.createdAt = now
        self.updatedAt = now
        self.exercise = exercise
        self.position = position
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.weight = weight
        self.weightStep = weightStep ?? exercise.equipment.defaultWeightStep
        self.restSeconds = restSeconds
    }

    public var target: Target {
        Target(sets: targetSets, reps: targetReps, weight: weight)
    }

    public var exerciseName: String {
        exercise?.name ?? ""
    }

    /// Takes over Target, Weight Step and Rest; only touches `updatedAt` if something changed.
    func copySettings(from source: PlannedExercise, now: Date) {
        guard
            targetSets != source.targetSets || targetReps != source.targetReps || weight != source.weight
                || weightStep != source.weightStep || restSeconds != source.restSeconds
        else { return }
        targetSets = source.targetSets
        targetReps = source.targetReps
        weight = source.weight
        weightStep = source.weightStep
        restSeconds = source.restSeconds
        updatedAt = now
    }
}
