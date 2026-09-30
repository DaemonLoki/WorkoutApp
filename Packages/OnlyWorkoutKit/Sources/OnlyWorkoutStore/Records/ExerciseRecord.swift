import Foundation
import OnlyWorkoutCore

public struct ExerciseRecord: SyncRecord, Codable, Equatable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var name: String
    public var equipment: String
    public var muscleGroups: [String]
    public var catalogKey: String?
    public var stravaExerciseType: String?
    public var archivedAt: Date?

    init(_ model: Exercise) {
        id = model.id
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        deletedAt = model.deletedAt
        name = model.name
        equipment = model.equipmentRaw
        muscleGroups = model.muscleGroupsRaw
        catalogKey = model.catalogKey
        stravaExerciseType = model.stravaExerciseType
        archivedAt = model.archivedAt
    }

    func write(to model: Exercise) {
        model.createdAt = createdAt
        model.updatedAt = updatedAt
        model.deletedAt = deletedAt
        model.name = name
        model.equipmentRaw = equipment
        model.muscleGroupsRaw = muscleGroups
        model.catalogKey = catalogKey
        model.stravaExerciseType = stravaExerciseType
        model.archivedAt = archivedAt
    }
}
