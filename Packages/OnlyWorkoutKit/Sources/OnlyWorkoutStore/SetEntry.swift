import Foundation
import OnlyWorkoutCore
import SwiftData

/// A Set as stored. Named `SetEntry` because `Set` is taken by Swift's collection type.
@Model
public final class SetEntry {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    /// The `updatedAt` the cloud is known to have; local only, never synced.
    public var syncedUpdatedAt: Date?

    public var sessionExercise: SessionExercise?
    /// 1-based position within its Session Exercise.
    public var number: Int
    public var reps: Int
    public var weight: Double
    public var isExtra: Bool
    public var completedAt: Date

    public init(id: UUID = UUID(), number: Int, reps: Int, weight: Double, isExtra: Bool, completedAt: Date) {
        self.id = id
        self.createdAt = completedAt
        self.updatedAt = completedAt
        self.number = number
        self.reps = reps
        self.weight = weight
        self.isExtra = isExtra
        self.completedAt = completedAt
    }

    public var loggedSet: LoggedSet {
        LoggedSet(reps: reps, weight: weight, isExtra: isExtra)
    }
}
