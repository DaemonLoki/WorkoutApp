import Foundation

/// A progress moment shown on the Session Summary, rendered from a handwritten template (README §9).
public enum MotivationEvent: Hashable, Codable, Sendable {
    case stepUp(exercise: String, from: Double, to: Double, gainSinceFirst: Double?, firstDate: Date?)
    /// A Step Up accepted as one more rep per Set.
    case repStepUp(exercise: String, sets: Int, fromReps: Int, toReps: Int)
    case targetHit(exercise: String, target: Target)
    case newBest(exercise: String, set: LoggedSet)
    /// First Session back after a Layoff.
    case comeback
}
