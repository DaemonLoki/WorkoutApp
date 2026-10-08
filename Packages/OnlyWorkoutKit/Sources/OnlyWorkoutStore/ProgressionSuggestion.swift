import Foundation
import OnlyWorkoutCore
import SwiftData

/// A Step Up or Step Down offered for a Planned Exercise, and what the user did with it.
@Model
public final class ProgressionSuggestion {
    public enum Status: String, Codable, Sendable {
        case pending, accepted, dismissed, superseded
    }

    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    /// The `updatedAt` the cloud is known to have; local only, never synced.
    public var syncedUpdatedAt: Date?

    public var plannedExerciseID: UUID
    public var kindRaw: String
    public var reasonRaw: String
    public var fromWeight: Double
    public var toWeight: Double
    /// `nil` for suggestions from before reps could change; then the reps don't change.
    public var fromReps: Int?
    public var toReps: Int?
    public var sourceSessionID: UUID?
    public var statusRaw: String
    public var resolvedAt: Date?

    public init(
        id: UUID = UUID(), plannedExerciseID: UUID, suggestion: WeightSuggestion, sourceSessionID: UUID?, now: Date
    ) {
        self.id = id
        self.createdAt = now
        self.updatedAt = now
        self.plannedExerciseID = plannedExerciseID
        self.kindRaw = suggestion.kind.rawValue
        self.reasonRaw = suggestion.reason.rawValue
        self.fromWeight = suggestion.fromWeight
        self.toWeight = suggestion.toWeight
        self.fromReps = suggestion.fromReps
        self.toReps = suggestion.toReps
        self.sourceSessionID = sourceSessionID
        self.statusRaw = Status.pending.rawValue
    }

    public var kind: WeightSuggestion.Kind {
        WeightSuggestion.Kind(rawValue: kindRaw) ?? .stepUp
    }

    public var reason: WeightSuggestion.Reason {
        WeightSuggestion.Reason(rawValue: reasonRaw) ?? .targetHit
    }

    public var status: Status {
        get { Status(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    public var suggestion: WeightSuggestion {
        WeightSuggestion(
            kind: kind, reason: reason, fromWeight: fromWeight, toWeight: toWeight, fromReps: fromReps ?? 0,
            toReps: toReps ?? fromReps ?? 0)
    }
}
