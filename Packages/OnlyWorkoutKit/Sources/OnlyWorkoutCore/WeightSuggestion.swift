/// A Step Up or Step Down the app offers for a Planned Exercise: a new weight, new reps per Set, or a choice of both.
public struct WeightSuggestion: Hashable, Codable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case stepUp, stepDown
    }

    public enum Reason: String, Codable, Sendable {
        case targetHit, stall, layoff
    }

    /// What a suggestion changes about the Target.
    public enum Change: String, Codable, Sendable {
        case weight, reps
    }

    public var kind: Kind
    public var reason: Reason
    public var fromWeight: Double
    /// Equal to `fromWeight` when the weight doesn't change.
    public var toWeight: Double
    public var fromReps: Int
    /// Equal to `fromReps` when the reps don't change.
    public var toReps: Int

    public init(kind: Kind, reason: Reason, fromWeight: Double, toWeight: Double, fromReps: Int, toReps: Int) {
        self.kind = kind
        self.reason = reason
        self.fromWeight = fromWeight
        self.toWeight = toWeight
        self.fromReps = fromReps
        self.toReps = toReps
    }

    /// The changes on offer: a Step Up after a Target Hit offers both, so the user picks one.
    public var changes: [Change] {
        (toWeight != fromWeight ? [.weight] : []) + (toReps != fromReps ? [.reps] : [])
    }

    /// Only `change` applied: what accepting it does, and what an accepted suggestion keeps on record.
    public func choosing(_ change: Change) -> WeightSuggestion {
        var chosen = self
        switch change {
        case .weight: chosen.toReps = fromReps
        case .reps: chosen.toWeight = fromWeight
        }
        return chosen
    }
}
