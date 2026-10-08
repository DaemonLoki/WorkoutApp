import Foundation
import Observation
import OnlyWorkoutConnectivity
import OnlyWorkoutCore
import OnlyWorkoutStore
import WidgetKit

/// The Watch app's state: the plan received from the iPhone and the Session it runs (README §8).
@Observable
final class WatchModel {
    static let startNextUpURL = URL(string: "onlyworkout://start")
    /// Watch Sessions this recent are resent to the iPhone until it certainly has them; merging makes repeats harmless.
    static let resendWindow: TimeInterval = 14 * 86_400
    /// `UserDefaults` key of the iPhone's Rest Timer setting, as last received.
    static let usesRestTimerKey = "usesRestTimer"

    let log: TrainingLog
    let recorder = WorkoutRecorder()
    private(set) var runner: SessionRunner?
    /// Bumped when records arrive, so views re-read the plan.
    private(set) var planVersion = 0

    @ObservationIgnored private let link = PhoneWatchLink()
    @ObservationIgnored private var pendingStart: PhoneWatchLink.StartRequest?

    init(log: TrainingLog) {
        self.log = log
        link.onReceiveRecords = { [weak self] batch in
            guard let self else { return }
            log.apply(batch)
            planVersion += 1
            updateComplication()
            // Sessions deleted on the iPhone arrive as tombstones; only the Watch can delete their workouts.
            Task { await WorkoutRecorder.deleteWorkouts(ofDeletedSessionsIn: self.log, recordedOn: .watch) }
        }
        link.onReceiveSettings = { settings in
            UserDefaults.standard.set(settings.usesRestTimer, forKey: Self.usesRestTimerKey)
        }
        link.onStartRequest = { [weak self] request in self?.pendingStart = request }
        link.onActivate = { [weak self] in self?.sendToPhone() }
        link.onShouldResend = { [weak self] in self?.sendToPhone() }
        link.activate()
        recorder.onRemoteData = { [weak self] data in
            guard case .command(let command) = MirrorMessage(data: data) else { return }
            self?.runner?.perform(command)
        }
        resumeUnfinishedSession()
    }

    var workouts: [Workout] {
        _ = planVersion
        return log.workouts()
    }

    var nextUp: Workout? {
        log.nextUp(in: workouts)
    }

    // MARK: - Sessions

    /// Starts a Session from the wrist. It runs even without Health access (then without heart rate or mirroring).
    func start(_ workout: Workout) {
        guard runner == nil else { return }
        let (session, engine) = log.startSession(workout, recordedOn: .watch, usesRestTimer: usesRestTimer)
        run(SessionRunner(session: session, engine: engine, log: log))
        let startedAt = session.startedAt
        Task {
            await recorder.requestAuthorization()
            await recorder.start(at: startedAt, mirrorToCompanion: true)
            broadcast()
        }
    }

    private var usesRestTimer: Bool {
        UserDefaults.standard.object(forKey: Self.usesRestTimerKey) as? Bool ?? true
    }

    func startNextUp() {
        if let nextUp { start(nextUp) }
    }

    /// The iPhone launched this app to run a Session; its start request travels in the application context.
    /// The Watch only takes over if it can mirror the Session back in time; otherwise the iPhone runs it,
    /// so a Session never runs on both devices. (Health access is granted by starting once on the Watch.)
    func handleStartFromPhone() {
        link.receiveLatestContext()
        guard runner == nil, recorder.canSaveWorkouts, let request = pendingStart, request.isFresh(),
            let workout = workouts.first(where: { $0.id == request.workoutID })
        else { return }
        pendingStart = nil
        Task {
            let startedAt = Date.now
            guard await recorder.start(at: startedAt, mirrorToCompanion: true) else { return }
            guard request.isFresh(), runner == nil else {
                await recorder.discard()
                return
            }
            let (session, engine) = log.startSession(
                workout, recordedOn: .watch, usesRestTimer: usesRestTimer, now: startedAt)
            run(SessionRunner(session: session, engine: engine, log: log))
            broadcast()
        }
    }

    func recoverSession() {
        Task { _ = await recorder.recover() }
        resumeUnfinishedSession()
    }

    func finish() {
        runner?.finish()
    }

    /// Leaves the Summary: saves the workout to Health and queues the Session for the iPhone.
    func closeSession() {
        guard let runner else { return }
        self.runner = nil
        let session = runner.session
        Task {
            let workoutID = await recorder.finish(at: session.endedAt ?? .now)
            log.attachHealthWorkout(workoutID, to: session)
            sendToPhone()
            updateComplication()
        }
    }

    /// Queues the plan (answered suggestions, changed weights) and recent Watch Sessions for the iPhone.
    private func sendToPhone() {
        var batch = log.exportPlan()
        batch.merge(
            log.exportSessions(
                log.finishedSessions(recordedOn: .watch, since: .now.addingTimeInterval(-Self.resendWindow))))
        link.send(batch)
    }

    private func run(_ runner: SessionRunner) {
        self.runner = runner
        runner.onChange = { [weak self] in self?.broadcast() }
        updateComplication()
    }

    private func resumeUnfinishedSession() {
        guard runner == nil, let session = log.inProgressSession(), session.recordedOn == .watch,
            let engine = log.restoreEngine(of: session)
        else { return }
        run(SessionRunner(session: session, engine: engine, log: log))
    }

    /// Sends the current state to the iPhone, which mirrors it.
    private func broadcast() {
        guard let runner,
            let data = MirrorMessage.state(MirrorState(runner: runner, heartRate: recorder.heartRate)).encoded()
        else { return }
        Task { await recorder.send(data) }
    }

    private func updateComplication() {
        NextUpStore.save(workoutName: nextUp?.name)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
