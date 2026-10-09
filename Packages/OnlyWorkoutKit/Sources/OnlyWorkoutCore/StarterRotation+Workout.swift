extension StarterRotation {
    /// One Workout of a Starter Rotation.
    public struct Workout: Hashable, Sendable {
        public let focus: Focus
        public let plannedExercises: [PlannedExercise]

        public init(focus: Focus, plannedExercises: [PlannedExercise]) {
            self.focus = focus
            self.plannedExercises = plannedExercises
        }
    }
}
