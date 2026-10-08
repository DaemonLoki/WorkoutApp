import Foundation
import Observation
import OnlyWorkoutConnectivity
import OnlyWorkoutCore
import OnlyWorkoutStore

/// A Session running on the Watch, shown on this iPhone. Taps become commands for the Watch (README §6).
@Observable
final class MirroredSession: SessionDriver {
    private(set) var state: MirrorState?
    @ObservationIgnored private let recorder: WorkoutRecorder
    @ObservationIgnored private let liveActivity = LiveActivityController()
    @ObservationIgnored private var hasLiveActivity = false

    init(recorder: WorkoutRecorder) {
        self.recorder = recorder
        recorder.onRemoteData = { [weak self] data in
            guard let self, case .state(let state) = MirrorMessage(data: data) else { return }
            self.receive(state)
        }
    }

    var workoutName: String { state?.workoutName ?? "" }
    var startedAt: Date { state?.startedAt ?? .now }
    var engine: SessionEngine { state?.engine ?? SessionEngine(exercises: []) }
    var offer: SessionOffer? { state?.offer }
    var summary: SessionSummary? { state?.summary }
    var restEndCount: Int { state?.restEndCount ?? 0 }
    var loggedSetCount: Int { state?.loggedSetCount ?? 0 }
    var heartRate: Double? { state?.heartRate }
    var isWaitingForWatch: Bool { state == nil }

    func weightStep(for exerciseID: UUID) -> Double { state?.exercises[exerciseID]?.weightStep ?? 2.5 }
    func usesAddedWeight(for exerciseID: UUID) -> Bool { state?.exercises[exerciseID]?.usesAddedWeight ?? false }

    func completeSet(reps: Int, weight: Double) { send(.completeSet(reps: reps, weight: weight)) }
    func finishRest() { send(.finishRest) }
    func extendRest() { send(.extendRest) }
    func skipSet(of exerciseID: UUID) { send(.skipSet(exerciseID)) }
    func skip(_ exerciseID: UUID) { send(.skip(exerciseID)) }
    func doLater(_ exerciseID: UUID) { send(.doLater(exerciseID)) }
    func addExtraSet(_ exerciseID: UUID) { send(.addExtraSet(exerciseID)) }
    func answer(_ offer: SessionOffer, accept: Bool, choosing change: WeightSuggestion.Change?) {
        send(.answer(offer, accept: accept, change: change))
    }
    func finish() { send(.finish) }

    func editSet(exerciseID: UUID, at index: Int, reps: Int, weight: Double) {
        send(.editSet(exerciseID: exerciseID, index: index, reps: reps, weight: weight))
    }

    /// Live Activities can only start in the foreground (ActivityKit); the Watch may have started this
    /// Session while the iPhone was in a pocket, so try again whenever the app becomes active.
    func appDidBecomeActive() {
        startLiveActivityIfNeeded()
    }

    private func receive(_ state: MirrorState) {
        self.state = state
        if state.summary != nil {
            liveActivity.end()
            hasLiveActivity = false
        } else if hasLiveActivity {
            liveActivity.update(state: liveActivityState)
        } else {
            startLiveActivityIfNeeded()
        }
    }

    private func startLiveActivityIfNeeded() {
        guard !hasLiveActivity, state != nil, summary == nil else { return }
        hasLiveActivity = liveActivity.start(workoutName: workoutName, state: liveActivityState)
    }

    private func send(_ command: MirrorCommand) {
        guard let data = MirrorMessage.command(command).encoded() else { return }
        let recorder = recorder
        Task { await recorder.send(data) }
    }
}
