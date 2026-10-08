import Foundation
import OnlyWorkoutCore

public struct WorkoutRecord: SyncRecord, Codable, Equatable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var name: String
    public var rotationIndex: Int
    public var usesRestTimer: Bool

    init(_ model: Workout) {
        id = model.id
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        deletedAt = model.deletedAt
        name = model.name
        rotationIndex = model.rotationIndex
        usesRestTimer = model.usesRestTimer
    }

    func write(to model: Workout) {
        model.createdAt = createdAt
        model.updatedAt = updatedAt
        model.deletedAt = deletedAt
        model.name = name
        model.rotationIndex = rotationIndex
        model.usesRestTimer = usesRestTimer
    }
}

extension WorkoutRecord {
    private enum CodingKeys: String, CodingKey {
        case id, createdAt, updatedAt, deletedAt, name, rotationIndex, usesRestTimer
    }

    /// Decodes records from before a column existed, e.g. pulled before the cloud migration ran.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        name = try container.decode(String.self, forKey: .name)
        rotationIndex = try container.decode(Int.self, forKey: .rotationIndex)
        usesRestTimer = try container.decodeIfPresent(Bool.self, forKey: .usesRestTimer) ?? true
    }
}
