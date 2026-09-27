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
            isSkipped ? 0 : max(0, totalSets - sets.count)
        }

        /// The next Set to log is beyond the Target.
        var nextSetIsExtra: Bool {
            sets.count >= target.sets
        }

        /// This exercise's outcome as progression input.
        public func result(on date: Date) -> ExerciseResult {
            ExerciseResult(date: date, target: target, sets: sets)
        }

        public var status: SessionExerciseStatus {
            if isSkipped { .skipped } else if remainingSets == 0 { .done } else { .pending }
        }
    }
}
