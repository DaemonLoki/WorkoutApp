/// Picks Next Up from the Rotation (README §5).
public enum Rotation {
    /// - Parameters:
    ///   - workouts: Workout identifiers in Rotation order.
    ///   - lastStarted: The Workout of the most recently started Session, if any.
    public static func nextUp<ID: Equatable>(in workouts: [ID], lastStarted: ID?) -> ID? {
        guard let lastStarted, let index = workouts.firstIndex(of: lastStarted) else { return workouts.first }
        let next = workouts.index(after: index)
        return next == workouts.endIndex ? workouts.first : workouts[next]
    }
}
