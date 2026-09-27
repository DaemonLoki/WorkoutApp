import Foundation
import OnlyWorkoutCore
import SwiftData

/// A single movement such as Pull-up or Squat (see CONTEXT.md).
@Model
public final class Exercise {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public var name: String
    public var equipmentRaw: String
    public var muscleGroupsRaw: [String]
    /// Set for Exercise Catalog entries; `nil` for Custom Exercises.
    public var catalogKey: String?
    /// Strava exercise type for uploads (M4).
    public var stravaExerciseType: String?
    /// Archived instead of deleted once it has history.
    public var archivedAt: Date?

    public init(
        id: UUID = UUID(), name: String, equipment: Equipment, muscleGroups: [MuscleGroup], catalogKey: String? = nil,
        now: Date = .now
    ) {
        self.id = id
        self.createdAt = now
        self.updatedAt = now
        self.name = name
        self.equipmentRaw = equipment.rawValue
        self.muscleGroupsRaw = muscleGroups.map(\.rawValue)
        self.catalogKey = catalogKey
    }

    public var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .machine }
        set { equipmentRaw = newValue.rawValue }
    }

    public var muscleGroups: [MuscleGroup] {
        get { muscleGroupsRaw.compactMap(MuscleGroup.init(rawValue:)) }
        set { muscleGroupsRaw = newValue.map(\.rawValue) }
    }

    public var isCustom: Bool {
        catalogKey == nil
    }
}
