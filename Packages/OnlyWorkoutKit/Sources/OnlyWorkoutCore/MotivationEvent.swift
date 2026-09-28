import Foundation

/// A progress moment shown on the Session Summary, rendered from a handwritten template (README §9).
public enum MotivationEvent: Hashable, Codable, Sendable {
    case stepUp(exercise: String, from: Double, to: Double, gainSinceFirst: Double?, firstDate: Date?)
    case targetHit(exercise: String, target: Target)
    case newBest(exercise: String, set: LoggedSet)
    /// First Session back after a Layoff.
    case comeback
}
