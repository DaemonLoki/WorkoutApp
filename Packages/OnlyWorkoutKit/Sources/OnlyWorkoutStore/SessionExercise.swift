import Foundation
import OnlyWorkoutCore
import SwiftData

/// Snapshot of a Planned Exercise inside a Session.
@Model
public final class SessionExercise {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public var session: Session?
    public var exerciseID: UUID
    public var plannedExerciseID: UUID?
    public var exerciseName: String
    public var position: Int
    public var supersetID: UUID?
    public var targetSets: Int
    public var targetReps: Int
    public var targetWeight: Double
    public var statusRaw: String
    /// Planned Sets passed over without being performed.
    public var skippedSets: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.sessionExercise)
    public var sets: [SetEntry] = []

    public init(
        id: UUID = UUID(), exerciseID: UUID, plannedExerciseID: UUID?, exerciseName: String, position: Int,
        supersetID: UUID?, target: Target, now: Date
    ) {
        self.id = id
        self.createdAt = now
        self.updatedAt = now
        self.exerciseID = exerciseID
        self.plannedExerciseID = plannedExerciseID
        self.exerciseName = exerciseName
        self.position = position
        self.supersetID = supersetID
        self.targetSets = target.sets
        self.targetReps = target.reps
        self.targetWeight = target.weight
        self.statusRaw = SessionExerciseStatus.pending.rawValue
    }

    public var status: SessionExerciseStatus {
        get { SessionExerciseStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    public var target: Target {
        Target(sets: targetSets, reps: targetReps, weight: targetWeight)
    }

    public var orderedSets: [SetEntry] {
        sets.filter { $0.deletedAt == nil }.sorted { $0.number < $1.number }
    }

    /// Progression input for this exercise in this Session.
    public var result: ExerciseResult {
        ExerciseResult(
            date: session?.startedAt ?? createdAt, target: target, sets: orderedSets.map(\.loggedSet),
            plannedExerciseID: plannedExerciseID, skippedSets: skippedSets)
    }
}
