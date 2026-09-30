import Foundation
import OnlyWorkoutCore

public struct PlannedExerciseRecord: SyncRecord, Codable, Equatable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var workoutID: UUID?
    public var exerciseID: UUID?
    public var position: Int
    public var supersetID: UUID?
    public var linkID: UUID?
    public var targetSets: Int
    public var targetReps: Int
    public var weight: Double
    public var weightStep: Double
    public var restSeconds: Int

    init(_ model: PlannedExercise) {
        id = model.id
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        deletedAt = model.deletedAt
        workoutID = model.workout?.id
        exerciseID = model.exercise?.id
        position = model.position
        supersetID = model.supersetID
        linkID = model.linkID
        targetSets = model.targetSets
        targetReps = model.targetReps
        weight = model.weight
        weightStep = model.weightStep
        restSeconds = model.restSeconds
    }

    func write(to model: PlannedExercise) {
        model.createdAt = createdAt
        model.updatedAt = updatedAt
        model.deletedAt = deletedAt
        model.position = position
        model.supersetID = supersetID
        model.linkID = linkID
        model.targetSets = targetSets
        model.targetReps = targetReps
        model.weight = weight
        model.weightStep = weightStep
        model.restSeconds = restSeconds
    }
}
