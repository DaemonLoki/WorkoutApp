import Foundation
import OnlyWorkoutCore

public struct SuggestionRecord: SyncRecord, Codable, Equatable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var plannedExerciseID: UUID
    public var kind: String
    public var reason: String
    public var fromWeight: Double
    public var toWeight: Double
    public var sourceSessionID: UUID?
    public var status: String
    public var resolvedAt: Date?

    init(_ model: ProgressionSuggestion) {
        id = model.id
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        deletedAt = model.deletedAt
        plannedExerciseID = model.plannedExerciseID
        kind = model.kindRaw
        reason = model.reasonRaw
        fromWeight = model.fromWeight
        toWeight = model.toWeight
        sourceSessionID = model.sourceSessionID
        status = model.statusRaw
        resolvedAt = model.resolvedAt
    }

    func write(to model: ProgressionSuggestion) {
        model.createdAt = createdAt
        model.updatedAt = updatedAt
        model.deletedAt = deletedAt
        model.plannedExerciseID = plannedExerciseID
        model.kindRaw = kind
        model.reasonRaw = reason
        model.fromWeight = fromWeight
        model.toWeight = toWeight
        model.sourceSessionID = sourceSessionID
        model.statusRaw = status
        model.resolvedAt = resolvedAt
    }
}
