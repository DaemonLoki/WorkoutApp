import Foundation
import OnlyWorkoutCore

/// What the Summary screen shows after a Session.
public struct SessionSummary: Hashable, Codable, Sendable {
    public let sessionID: UUID
    public let workoutName: String
    public let duration: TimeInterval
    public let setCount: Int
    public let volume: Double
    public let events: [MotivationEvent]
}
