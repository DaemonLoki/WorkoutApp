import Foundation
import OnlyWorkoutCore

/// A Step Up or Step Down card waiting for an answer during a Session.
public struct SessionOffer: Identifiable, Hashable, Codable, Sendable {
    /// The stored `ProgressionSuggestion` id.
    public let id: UUID
    /// The Session Exercise it belongs to.
    public let exerciseID: UUID
    public let exerciseName: String
    public let suggestion: WeightSuggestion

    public init(id: UUID, exerciseID: UUID, exerciseName: String, suggestion: WeightSuggestion) {
        self.id = id
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.suggestion = suggestion
    }
}
