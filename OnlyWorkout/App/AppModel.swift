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
    /// `UserDefaults` key of Settings → Apple Watch → Start Sessions on Apple Watch; device-local, on by default.
    static let startsSessionsOnWatchKey = "startsSessionsOnWatch"
    /// `UserDefaults` key of Settings → Sessions → Rest Timer; device-local (shared with the Watch), on by default.
    static let usesRestTimerKey = "usesRestTimer"
    /// `UserDefaults` key set once onboarding has finished; device-local (README §7 Onboarding).
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    /// `UserDefaults` key of the Equipment Access chosen in onboarding; device-local, reused by Recommendations.
    static let equipmentAccessKey = "equipmentAccess"

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
    /// The first-launch onboarding replaces the tabs until it finishes.
    private(set) var showsOnboarding: Bool
    /// A Workout created at the end of onboarding that Today opens in the Workout editor.
    var workoutToEdit: Workout?

    @ObservationIgnored private let link = PhoneWatchLink()
    @ObservationIgnored private let recorder: WorkoutRecorder?
    @ObservationIgnored private var watchStartTimeout: Task<Void, Never>?
    /// Set when the user continues past the Health explanation; the start waits until that sheet is gone.
    @ObservationIgnored private var startAfterHealthExplanation: Workout?

    /// - Parameters:
    ///   - usesHealth: `false` for UI tests, which run without Apple Health and without a Watch.
    ///   - showsOnboarding: decided by `needsOnboarding(log:)` before this model starts the Watch link.
    init(log: TrainingLog, services: CloudServices? = nil, usesHealth: Bool = true, showsOnboarding: Bool = false) {
        self.log = log
        self.showsOnboarding = showsOnboarding
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
        deleteHealthWorkouts()
        syncWithCloud()
    }

    // MARK: - Onboarding

    /// Onboarding is for a fresh install: nothing planned or performed yet (catalog Exercises don't count). A store
    /// that already has data, e.g. after updating from a version without onboarding, is marked as done silently.
    static func needsOnboarding(log: TrainingLog, defaults: UserDefaults = .standard) -> Bool {
        guard !defaults.bool(forKey: hasCompletedOnboardingKey) else { return false }
        guard log.workouts().isEmpty, log.lastStartedSession() == nil else {
            defaults.set(true, forKey: hasCompletedOnboardingKey)
            return false
        }
        return true
    }

    /// Ends onboarding for good and shows the tabs, opening `workout` in the editor when given.
    func finishOnboarding(editing workout: Workout? = nil) {
        UserDefaults.standard.set(true, forKey: Self.hasCompletedOnboardingKey)
        workoutToEdit = workout
        showsOnboarding = false
        publishToWatch()
        syncWithCloud()
    }

    /// Whether Apple Health would show its permission sheet; `false` without Apple Health.
    func healthNeedsAuthorization() async -> Bool {
        await recorder?.needsAuthorization() ?? false
    }

    func requestHealthAuthorization() async {
        await recorder?.requestAuthorization()
    }

    // MARK: - Starting

    /// Starts a Session, explaining Apple Health first if the permission hasn't been asked yet.
    func requestStart(_ workout: Workout) {
        guard activeSession == nil, startingOnWatch == nil else { return }
        nameUnnamedWorkouts()
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

    /// Runs the Session on the Watch when one is available and the setting allows it (it measures
    /// heart rate), otherwise here.
    private func start(_ workout: Workout) async {
        guard let recorder, link.canUseWatch, startsSessionsOnWatch else {
            startOnPhone(workout)
            return
        }
        startingOnWatch = workout
        link.requestStart(of: workout.id, with: log.watchSnapshot(), settings: watchSettings)
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

    private var startsSessionsOnWatch: Bool {
        UserDefaults.standard.object(forKey: Self.startsSessionsOnWatchKey) as? Bool ?? true
    }

    private var usesRestTimer: Bool {
        UserDefaults.standard.object(forKey: Self.usesRestTimerKey) as? Bool ?? true
    }

    private var watchSettings: PhoneWatchLink.Settings {
        PhoneWatchLink.Settings(usesRestTimer: usesRestTimer)
    }

    /// Also offered to the user while waiting for the Watch.
    func startOnPhone(_ workout: Workout) {
        watchStartTimeout?.cancel()
        startingOnWatch = nil
        guard activeSession == nil else { return }
        let (session, engine) = log.startSession(workout, recordedOn: .phone, usesRestTimer: usesRestTimer)
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

    // MARK: - Workouts

    /// A new Workout starts with an empty name (the editor shows the default as a placeholder);
    /// one left unnamed gets the default once its editor closes or it's started.
    func nameUnnamedWorkouts() {
        let now = Date.now
        for workout in log.workouts() where workout.name.trimmingCharacters(in: .whitespaces).isEmpty {
            workout.name = String(localized: .newWorkoutName)
            workout.updatedAt = now
        }
    }

    // MARK: - Sessions

    /// Deletes a past Session everywhere: soft delete, its Health workout, the Watch's copy and the cloud.
    func delete(_ session: Session) {
        log.delete(session)
        deleteHealthWorkouts()
        publishToWatch()
        syncWithCloud()
    }

    /// Deletes the Health workouts of deleted Sessions recorded here, wherever they were deleted.
    /// Those recorded on the Watch are deleted by the Watch, from the tombstones in its snapshot.
    private func deleteHealthWorkouts() {
        guard recorder != nil else { return }
        Task { await WorkoutRecorder.deleteWorkouts(ofDeletedSessionsIn: log, recordedOn: .phone) }
    }

    // MARK: - Suggestions

    func accept(_ suggestion: ProgressionSuggestion, choosing change: WeightSuggestion.Change? = nil) {
        log.accept(suggestion, choosing: change)
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
            deleteHealthWorkouts()
            publishToWatch()
            guard uploadsToStrava, let strava else { return }
            await strava.refresh()
            await strava.uploadPending()
        }
    }

    /// Sends the plan, recent history and Settings, so the Watch can run Sessions without the iPhone.
    func publishToWatch() {
        link.publish(log.watchSnapshot(), settings: watchSettings)
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
