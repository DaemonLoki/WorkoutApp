import Foundation
import SwiftData

/// A named, reusable plan made of Planned Exercises (see CONTEXT.md).
@Model
public final class Workout {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    /// The `updatedAt` the cloud is known to have; local only, never synced.
    public var syncedUpdatedAt: Date?

    public var name: String
    /// Position in the Rotation.
    public var rotationIndex: Int

    @Relationship(deleteRule: .cascade, inverse: \PlannedExercise.workout)
    public var plannedExercises: [PlannedExercise] = []

    public init(id: UUID = UUID(), name: String, rotationIndex: Int, now: Date = .now) {
        self.id = id
        self.createdAt = now
        self.updatedAt = now
        self.name = name
        self.rotationIndex = rotationIndex
    }

    /// Live Planned Exercises in Workout order.
    public var orderedPlannedExercises: [PlannedExercise] {
        plannedExercises.filter { $0.deletedAt == nil }.sorted { $0.position < $1.position }
    }
}
