extension StarterRotation {
    /// A catalog Exercise with its Target (without weight: people enter their own) and Rest.
    public struct PlannedExercise: Hashable, Sendable {
        public let catalogKey: String
        public let sets: Int
        public let reps: Int
        public let restSeconds: Int
        /// Forms a Superset with the next Planned Exercise of the Workout.
        public let supersetsWithNext: Bool

        public init(_ catalogKey: String, sets: Int, reps: Int, restSeconds: Int, supersetsWithNext: Bool = false) {
            self.catalogKey = catalogKey
            self.sets = sets
            self.reps = reps
            self.restSeconds = restSeconds
            self.supersetsWithNext = supersetsWithNext
        }
    }
}
