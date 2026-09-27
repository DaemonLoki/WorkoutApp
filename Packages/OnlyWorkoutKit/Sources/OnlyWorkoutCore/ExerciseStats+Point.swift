import Foundation

extension ExerciseStats {
    /// One Session on the progress chart.
    public struct Point: Hashable, Sendable {
        public var date: Date
        /// The heaviest weight used in the Session.
        public var workingWeight: Double
        /// The Target weight rose since the previous Session of the same Planned Exercise.
        public var isStepUp: Bool
    }
}
