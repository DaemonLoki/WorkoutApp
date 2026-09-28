import Foundation
import OnlyWorkoutCore

public struct SessionExerciseRecord: SyncRecord, Codable, Equatable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var sessionID: UUID?
    public var exerciseID: UUID
    public var plannedExerciseID: UUID?
    public var exerciseName: String
    public var position: Int
    public var supersetID: UUID?
    public var targetSets: Int
    public var targetReps: Int
    public var targetWeight: Double
    public var status: String

    init(_ model: SessionExercise) {
        id = model.id
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        deletedAt = model.deletedAt
        sessionID = model.session?.id
        exerciseID = model.exerciseID
        plannedExerciseID = model.plannedExerciseID
        exerciseName = model.exerciseName
        position = model.position
        supersetID = model.supersetID
        targetSets = model.targetSets
        targetReps = model.targetReps
        targetWeight = model.targetWeight
        status = model.statusRaw
    }

    func write(to model: SessionExercise) {
        model.createdAt = createdAt
        model.updatedAt = updatedAt
        model.deletedAt = deletedAt
        model.exerciseID = exerciseID
        model.plannedExerciseID = plannedExerciseID
        model.exerciseName = exerciseName
        model.position = position
        model.supersetID = supersetID
        model.targetSets = targetSets
        model.targetReps = targetReps
        model.targetWeight = targetWeight
        model.statusRaw = status
    }
}
