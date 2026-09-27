import Foundation

extension SessionEngine {
    /// What logging a Set changed.
    public struct CompletedSet: Hashable, Sendable {
        public var exerciseID: UUID
        /// This Set was the last planned one of its exercise, so Target Hit can now be evaluated.
        public var finishedPlannedSets: Bool
    }
}
