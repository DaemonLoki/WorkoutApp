import Foundation
import Observation
import OnlyWorkoutConnectivity
import OnlyWorkoutCore
import OnlyWorkoutStore

/// A Session run on this iPhone: the shared `SessionRunner` plus Live Activity, Rest notification and Apple Health.
@Observable
final class LocalSession: SessionDriver {
    let runner: SessionRunner
    @ObservationIgnored private let log: TrainingLog
    @ObservationIgnored private let recorder: WorkoutRecorder?
    @ObservationIgnored private let liveActivity = LiveActivityController()
    @ObservationIgnored private let restNotifier = RestNotifier()

    /// - Parameter recorder: `nil` when Apple Health isn't used (UI tests).
    init(runner: SessionRunner, log: TrainingLog, recorder: WorkoutRecorder?) {
        self.runner = runner
        self.log = log
        self.recorder = recorder
        runner.onChange = { [weak self] in self?.runnerChanged() }
        restNotifier.requestAuthorization()
        liveActivity.start(workoutName: runner.session.workoutName, state: liveActivityState)
        scheduleRestNotification()
        if let recorder, !recorder.isRunning {
            let startedAt = runner.session.startedAt
            Task { await recorder.start(at: startedAt, mirrorToCompanion: false) }
        }
    }

    var workoutName: String { runner.session.workoutName }
    var startedAt: Date { runner.session.startedAt }
    var engine: SessionEngine { runner.engine }
    var offer: SessionOffer? { runner.offer }
    var summary: SessionSummary? { runner.summary }
    var restEndCount: Int { runner.restEndCount }
    var loggedSetCount: Int { runner.loggedSetCount }
    var heartRate: Double? { recorder?.heartRate }
    var isWaitingForWatch: Bool { false }

    func weightStep(for exerciseID: UUID) -> Double { runner.weightStep(for: exerciseID) }
    func usesAddedWeight(for exerciseID: UUID) -> Bool { runner.usesAddedWeight(for: exerciseID) }

    func completeSet(reps: Int, weight: Double) { runner.completeSet(reps: reps, weight: weight) }
    func finishRest() { runner.finishRest() }
    func extendRest() { runner.extendRest() }
    func skipSet(of exerciseID: UUID) { runner.skipSet(of: exerciseID) }
    func skip(_ exerciseID: UUID) { runner.skip(exerciseID) }
    func doLater(_ exerciseID: UUID) { runner.doLater(exerciseID) }
    func addExtraSet(_ exerciseID: UUID) { runner.addExtraSet(exerciseID) }
    func answer(_ offer: SessionOffer, accept: Bool, choosing change: WeightSuggestion.Change?) {
        runner.answer(offer, accept: accept, choosing: change)
    }

    func editSet(exerciseID: UUID, at index: Int, reps: Int, weight: Double) {
        runner.editSet(exerciseID: exerciseID, at: index, reps: reps, weight: weight)
    }

    func finish() {
        runner.finish()
        restNotifier.cancel()
        liveActivity.end()
        guard let recorder else { return }
        let session = runner.session
        let log = log
        Task {
            let workoutID = await recorder.finish(at: session.endedAt ?? .now)
            log.attachHealthWorkout(workoutID, to: session)
        }
    }

    func appDidBecomeActive() {}

    private func runnerChanged() {
        guard summary == nil else { return }
        liveActivity.update(state: liveActivityState)
        scheduleRestNotification()
    }

    private func scheduleRestNotification() {
        if let rest = engine.rest {
            restNotifier.schedule(at: rest.endsAt, next: nextSetDescription)
        } else {
            restNotifier.cancel()
        }
    }
}
