import Foundation
import OnlyWorkoutCore

public struct SessionRecord: SyncRecord, Codable, Equatable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var workoutID: UUID?
    public var workoutName: String
    public var startedAt: Date
    public var endedAt: Date?
    public var recordedOn: String
    /// Travels between Watch and iPhone only; never to the cloud (README §11).
    public var healthWorkoutID: UUID?
    public var stravaActivityID: Int64?

    init(_ model: Session) {
        id = model.id
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        deletedAt = model.deletedAt
        workoutID = model.workoutID
        workoutName = model.workoutName
        startedAt = model.startedAt
        endedAt = model.endedAt
        recordedOn = model.recordedOnRaw
        healthWorkoutID = model.healthWorkoutID
        stravaActivityID = model.stravaActivityID
    }

    func write(to model: Session) {
        model.createdAt = createdAt
        model.updatedAt = updatedAt
        model.deletedAt = deletedAt
        model.workoutID = workoutID
        model.workoutName = workoutName
        model.startedAt = startedAt
        model.endedAt = endedAt
        model.recordedOnRaw = recordedOn
        model.healthWorkoutID = healthWorkoutID ?? model.healthWorkoutID
        model.stravaActivityID = stravaActivityID
    }
}
