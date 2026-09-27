/// One Set as performed: reps × weight (kg).
public struct LoggedSet: Hashable, Codable, Sendable {
    public var reps: Int
    public var weight: Double
    /// Added beyond the Target's Set count; ignored for progression.
    public var isExtra: Bool

    public init(reps: Int, weight: Double, isExtra: Bool = false) {
        self.reps = reps
        self.weight = weight
        self.isExtra = isExtra
    }

    /// Whether this Set is better than `other`: heavier, or equally heavy with more reps.
    public func beats(_ other: LoggedSet) -> Bool {
        (weight, reps) > (other.weight, other.reps)
    }
}
