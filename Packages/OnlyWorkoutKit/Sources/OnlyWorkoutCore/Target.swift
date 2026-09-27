/// The fixed number of Sets, reps per Set, and weight planned for a Planned Exercise.
public struct Target: Hashable, Codable, Sendable {
    public var sets: Int
    public var reps: Int
    /// Weight in kg. For bodyweight Exercises this is Added Weight.
    public var weight: Double

    public init(sets: Int, reps: Int, weight: Double) {
        self.sets = sets
        self.reps = reps
        self.weight = weight
    }
}
