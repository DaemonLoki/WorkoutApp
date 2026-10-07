import os

extension Logger {
    /// Strava failures, visible in Xcode's console and Console.app. Never log codes or tokens.
    public static let strava = Logger(subsystem: "com.stefanblos.OnlyWorkouts", category: "Strava")
}
