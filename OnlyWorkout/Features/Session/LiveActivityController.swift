import ActivityKit
import Foundation
import OnlyWorkoutLiveActivity

/// Starts, updates and ends the Session's Live Activity.
/// Holds only the activity's id: `Activity` isn't `Sendable`, so each task looks it up afresh.
final class LiveActivityController {
    typealias State = SessionActivityAttributes.ContentState

    private var activityID: String?

    /// - Returns: Whether a Live Activity is now showing (starting fails while the app is in the background).
    @discardableResult
    func start(workoutName: String, state: State) -> Bool {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return false }
        // A Session resumed after relaunch may still have its Live Activity.
        if let existing = Activity<SessionActivityAttributes>.activities.first(where: {
            $0.attributes.workoutName == workoutName
        }) {
            activityID = existing.id
            update(state: state)
            return true
        }
        activityID = try? Activity.request(
            attributes: SessionActivityAttributes(workoutName: workoutName),
            content: ActivityContent(state: state, staleDate: nil)
        ).id
        return activityID != nil
    }

    func update(state: State) {
        guard let activityID else { return }
        Task { await Self.update(id: activityID, state: state) }
    }

    func end() {
        guard let activityID else { return }
        self.activityID = nil
        Task { await Self.end(id: activityID) }
    }

    private nonisolated static func update(id: String, state: State) async {
        await activity(id: id)?.update(ActivityContent(state: state, staleDate: nil))
    }

    private nonisolated static func end(id: String) async {
        await activity(id: id)?.end(nil, dismissalPolicy: .immediate)
    }

    private nonisolated static func activity(id: String) -> Activity<SessionActivityAttributes>? {
        Activity<SessionActivityAttributes>.activities.first { $0.id == id }
    }
}
