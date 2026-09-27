/// A Step Up or Step Down the app offers for a Planned Exercise.
public struct WeightSuggestion: Hashable, Codable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case stepUp, stepDown
    }

    public enum Reason: String, Codable, Sendable {
        case targetHit, stall, layoff
    }

    public var kind: Kind
    public var reason: Reason
    public var fromWeight: Double
    public var toWeight: Double

    public init(kind: Kind, reason: Reason, fromWeight: Double, toWeight: Double) {
        self.kind = kind
        self.reason = reason
        self.fromWeight = fromWeight
        self.toWeight = toWeight
    }
}
