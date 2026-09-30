import Foundation
import OnlyWorkoutCore

public struct WorkoutRecord: SyncRecord, Codable, Equatable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var name: String
    public var rotationIndex: Int

    init(_ model: Workout) {
        id = model.id
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        deletedAt = model.deletedAt
        name = model.name
        rotationIndex = model.rotationIndex
    }

    func write(to model: Workout) {
        model.createdAt = createdAt
        model.updatedAt = updatedAt
        model.deletedAt = deletedAt
        model.name = name
        model.rotationIndex = rotationIndex
    }
}
