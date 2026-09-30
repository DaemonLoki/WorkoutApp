import Foundation
import OnlyWorkoutCore

public struct SetRecord: SyncRecord, Codable, Equatable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var sessionExerciseID: UUID?
    public var number: Int
    public var reps: Int
    public var weight: Double
    public var isExtra: Bool
    public var completedAt: Date

    init(_ model: SetEntry) {
        id = model.id
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        deletedAt = model.deletedAt
        sessionExerciseID = model.sessionExercise?.id
        number = model.number
        reps = model.reps
        weight = model.weight
        isExtra = model.isExtra
        completedAt = model.completedAt
    }

    func write(to model: SetEntry) {
        model.createdAt = createdAt
        model.updatedAt = updatedAt
        model.deletedAt = deletedAt
        model.number = number
        model.reps = reps
        model.weight = weight
        model.isExtra = isExtra
        model.completedAt = completedAt
    }
}
