import Foundation

extension SessionEngine {
    /// A Planned Exercise as performed in this Session: its Target snapshot and the Sets logged so far.
    public struct Exercise: Identifiable, Hashable, Codable, Sendable {
        /// The Session Exercise id.
        public let id: UUID
        public var name: String
        public var target: Target
        public var restSeconds: Int
        public var supersetID: UUID?
        public internal(set) var sets: [LoggedSet] = []
        public internal(set) var isSkipped = false
        /// Extra Sets requested beyond the Target.
        public internal(set) var extraSets = 0
        /// Sets passed over without being performed (e.g. the machine was taken); not owed again.
        public internal(set) var skippedSets = 0

        public init(id: UUID, name: String, target: Target, restSeconds: Int, supersetID: UUID? = nil) {
            self.id = id
            self.name = name
            self.target = target
            self.restSeconds = restSeconds
            self.supersetID = supersetID
        }

        /// Planned Sets plus requested extras.
        public var totalSets: Int {
            target.sets + extraSets
        }

        /// Sets still owed; a skipped exercise owes none.
        public var remainingSets: Int {
            isSkipped ? 0 : max(0, totalSets - progress)
        }

        /// Sets done or skipped: how far through its Sets this exercise is.
        var progress: Int {
            sets.count + skippedSets
        }

        /// The next Set to log is beyond the Target.
        var nextSetIsExtra: Bool {
            progress >= target.sets
        }

        /// This exercise's outcome as progression input.
        public func result(on date: Date) -> ExerciseResult {
            ExerciseResult(date: date, target: target, sets: sets, skippedSets: skippedSets)
        }

        public var status: SessionExerciseStatus {
            if isSkipped { .skipped } else if remainingSets == 0 { .done } else { .pending }
        }
    }
}

extension SessionEngine.Exercise {
    private enum CodingKeys: String, CodingKey {
        case id, name, target, restSeconds, supersetID, sets, isSkipped, extraSets, skippedSets
    }

    /// Decodes Sessions saved before a field existed (a Session may be resumed after an app update).
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        target = try container.decode(Target.self, forKey: .target)
        restSeconds = try container.decode(Int.self, forKey: .restSeconds)
        supersetID = try container.decodeIfPresent(UUID.self, forKey: .supersetID)
        sets = try container.decodeIfPresent([LoggedSet].self, forKey: .sets) ?? []
        isSkipped = try container.decodeIfPresent(Bool.self, forKey: .isSkipped) ?? false
        extraSets = try container.decodeIfPresent(Int.self, forKey: .extraSets) ?? 0
        skippedSets = try container.decodeIfPresent(Int.self, forKey: .skippedSets) ?? 0
    }
}
