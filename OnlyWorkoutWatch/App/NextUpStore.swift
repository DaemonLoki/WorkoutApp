import Foundation

/// Hands Next Up to the complication through the shared App Group.
enum NextUpStore {
    static let suiteName = "group.com.stefanblos.OnlyWorkout"
    static let key = "nextUpWorkoutName"

    static func save(workoutName: String?) {
        UserDefaults(suiteName: suiteName)?.set(workoutName, forKey: key)
    }
}
