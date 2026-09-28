import Foundation
import Observation
import OnlyWorkoutConnectivity
import OnlyWorkoutCore
import OnlyWorkoutStore

/// App-wide state: which Session is running and where, plus the link to the Watch.
@Observable
final class AppModel {
    /// A Session untouched for this long is treated as forgotten and ended (README §6).
    static let abandonedSessionInterval: TimeInterval = 6 * 3600
    /// How long to wait for the Watch to pick up a Session before running it on the iPhone.
    static let watchStartTimeout: Duration = .seconds(8)

    let log: TrainingLog
    var activeSession: ActiveSession?
    /// The Watch has been asked to start this Workout; waiting for it to mirror back.
    var startingOnWatch: Workout?
    /// Shown once, before the Apple Health permission sheet.
    var healthExplanationFor: Workout?

    @ObservationIgnored private let link = PhoneWatchLink()
    @ObservationIgnored private let recorder: WorkoutRecorder?
    @ObservationIgnored private var watchStartTimeout: Task<Void, Never>?

    /// - Parameter usesHealth: `false` for UI tests, which run without Apple Health and without a Watch.
    init(log: TrainingLog, usesHealth: Bool = true) {
        self.log = log
        recorder = usesHealth && WorkoutRecorder.isAvailable ? WorkoutRecorder() : nil

        link.onReceiveRecords = { [weak self] batch in
            self?.log.apply(batch)
            self?.publishToWatch()
        }
        link.onActivate = { [weak self] in self?.publishToWatch() }
        link.activate()
        recorder?.observeMirroredSessions { [weak self] in self?.followWatchSession() }

        resumeUnfinishedSession()
    }

    // MARK: - Starting

    /// Starts a Session, explaining Apple Health first if the permission hasn't been asked yet.
    func requestStart(_ workout: Workout) {
        guard activeSession == nil, startingOnWatch == nil else { return }
        guard let recorder else {
            startOnPhone(workout)
            return
        }
        Task {
            if await recorder.needsAuthorization() {
                healthExplanationFor = workout
            } else {
                await start(workout)
            }
        }
    }

    func continueAfterHealthExplanation() {
        guard let workout = healthExplanationFor else { return }
        healthExplanationFor = nil
        Task {
            await recorder?.requestAuthorization()
            await start(workout)
        }
    }

    /// Runs the Session on the Watch when one is available (it measures heart rate), otherwise here.
    private func start(_ workout: Workout) async {
        guard let recorder, link.canUseWatch else {
            startOnPhone(workout)
            return
        }
        startingOnWatch = workout
        link.requestStart(of: workout.id, with: log.watchSnapshot())
        do {
            try await recorder.startWatchApp()
        } catch {
            startOnPhone(workout)
            return
        }
        watchStartTimeout = Task { [weak self] in
            try? await Task.sleep(for: Self.watchStartTimeout)
            guard !Task.isCancelled, let self, self.startingOnWatch?.id == workout.id else { return }
            self.startOnPhone(workout)
        }
    }

    /// Also offered to the user while waiting for the Watch.
    func startOnPhone(_ workout: Workout) {
        watchStartTimeout?.cancel()
        startingOnWatch = nil
        guard activeSession == nil else { return }
        let (session, engine) = log.startSession(workout, recordedOn: .phone)
        let runner = SessionRunner(session: session, engine: engine, log: log)
        activeSession = ActiveSession(driver: LocalSession(runner: runner, log: log, recorder: recorder))
    }

    /// The Watch started (or took over) a Session and is mirroring it here.
    private func followWatchSession() {
        watchStartTimeout?.cancel()
        startingOnWatch = nil
        guard let recorder, activeSession == nil else { return }
        activeSession = ActiveSession(driver: MirroredSession(recorder: recorder))
    }

    // MARK: - Lifecycle

    func closeSession() {
        activeSession = nil
        publishToWatch()
    }

    func appDidBecomeActive() {
        activeSession?.driver.appDidBecomeActive()
        publishToWatch()
    }

    func appDidEnterBackground() {
        publishToWatch()
    }

    /// Sends the plan and recent history, so the Watch can run Sessions without the iPhone.
    func publishToWatch() {
        link.publish(log.watchSnapshot())
    }

    private func resumeUnfinishedSession() {
        guard let session = log.inProgressSession(), session.recordedOn == .phone,
            var engine = log.restoreEngine(of: session)
        else { return }
        if Date.now.timeIntervalSince(session.updatedAt) > Self.abandonedSessionInterval {
            engine.end()
            log.finish(session, engine: engine, now: session.updatedAt)
        } else {
            let runner = SessionRunner(session: session, engine: engine, log: log)
            activeSession = ActiveSession(driver: LocalSession(runner: runner, log: log, recorder: recorder))
        }
    }
}
