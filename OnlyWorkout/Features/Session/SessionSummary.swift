import Foundation
import OnlyWorkoutCore

/// What the Summary screen shows after a Session.
struct SessionSummary: Hashable {
    let sessionID: UUID
    let workoutName: String
    let duration: TimeInterval
    let setCount: Int
    let volume: Double
    let events: [MotivationEvent]
}
