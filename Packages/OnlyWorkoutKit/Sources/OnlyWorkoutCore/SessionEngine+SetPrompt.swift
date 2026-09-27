import Foundation

extension SessionEngine {
    /// The Set the user should perform next, with reps and weight prefilled.
    public struct SetPrompt: Hashable, Sendable {
        public var exerciseID: UUID
        public var setNumber: Int
        public var totalSets: Int
        public var reps: Int
        public var weight: Double
        public var isExtra: Bool
    }
}
