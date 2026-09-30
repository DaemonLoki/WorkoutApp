import HealthKit
import WatchKit

/// Receives the iPhone's `startWatchApp(toHandle:)` launch and recovers a Session after termination.
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    var model: WatchModel?

    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        model?.handleStartFromPhone()
    }

    func handleActiveWorkoutRecovery() {
        model?.recoverSession()
    }
}
