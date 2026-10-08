import Foundation
import Observation
import OnlyWorkoutConnectivity
import OnlyWorkoutCore
import OnlyWorkoutStore
import OnlyWorkoutSync
import UIKit

/// App-wide state: which Session is running and where, plus the links to the Watch, the cloud and Strava.
@Observable
final class AppModel {
    /// A Session untouched for this long is treated as forgotten and ended (README §6).
    static let abandonedSessionInterval: TimeInterval = 6 * 3600

    let log: TrainingLog
    /// `nil` when this build has no Supabase configuration, and in UI tests.
    let cloud: CloudSync?
    /// Same; Strava rides on the cloud account (README §12).
    let strava: StravaLink?
    var activeSession: ActiveSession?
    /// The Watch has been asked to start this Workout; waiting for it to mirror back.
    var startingOnWatch: Workout?
    /// Shown once, before the Apple Health permission sheet.
    var healthExplanationFor: Workout?

    @ObservationIgnored private let link = PhoneWatchLink()
    @ObservationIgnored private let recorder: WorkoutRecorder?
    @ObservationIgnored private var watchStartTimeout: Task<Void, Never>?
    /// Set when the user continues past the Health explanation; the start waits until that sheet is gone.
    @ObservationIgnored private var startAfterHealthExplanation: Workout?

    /// - Parameter usesHealth: `false` for UI tests, which run without Apple Health and without a Watch.
    init(log: TrainingLog, services: CloudServices? = nil, usesHealth: Bool = true) {
        self.log = log
        cloud = services?.sync
        strava = services?.strava
        recorder = usesHealth && WorkoutRecorder.isAvailable ? WorkoutRecorder() : nil

        link.onReceiveRecords = { [weak self] batch in
            self?.log.apply(batch)
            self?.publishToWatch()
            self?.syncWithCloud()
        }
        link.onActivate = { [weak self] in self?.publishToWatch() }
        link.activate()
        recorder?.observeMirroredSessions { [weak self] in self?.followWatchSession() }
        // The upload mark is owed to the cloud right away, so another device never uploads again.
        strava?.didUpload = { [weak self] in self?.syncWithCloud(uploadsToStrava: false) }

        resumeUnfinishedSession()
        syncWithCloud()
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

    /// The user tapped Continue: close the explanation first. HealthKit presents its permission sheet
    /// on top of whatever is showing, and fails silently if that is a sheet still being dismissed.
    func continueAfterHealthExplanation() {
        startAfterHealthExplanation = healthExplanationFor
        healthExplanationFor = nil
    }

    /// Called once the explanation sheet has fully disappeared.
    func healthExplanationDismissed() {
        guard let workout = startAfterHealthExplanation else { return }
        startAfterHealthExplanation = nil
        Task {
            await recorder?.requestAuthorization()
            // HealthKit's own sheet may still be animating away; presenting the Session now would fail too.
            await UIApplication.shared.waitUntilNothingIsPresented()
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
            try? await Task.sleep(for: PhoneWatchLink.watchStartTimeout)
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
        syncWithCloud()
    }

    func appDidBecomeActive() {
        activeSession?.driver.appDidBecomeActive()
        publishToWatch()
        syncWithCloud()
    }

    func appDidEnterBackground() {
        publishToWatch()
    }

    // MARK: - Suggestions

    func accept(_ suggestion: ProgressionSuggestion) {
        log.accept(suggestion)
        syncWithCloud()
    }

    func dismiss(_ suggestion: ProgressionSuggestion) {
        log.dismiss(suggestion)
        syncWithCloud()
    }

    // MARK: - Sync

    /// Pushes and pulls when signed in (README §10), hands whatever arrived on to the Watch, then uploads
    /// finished Sessions to Strava. Pulling first brings in upload marks from other devices.
    func syncWithCloud(uploadsToStrava: Bool = true) {
        guard let cloud else { return }
        Task {
            await cloud.sync()
            publishToWatch()
            guard uploadsToStrava, let strava else { return }
            await strava.refresh()
            await strava.uploadPending()
        }
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
