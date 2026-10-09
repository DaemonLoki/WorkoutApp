import Foundation
import Observation
import OnlyWorkoutCore
import OnlyWorkoutStore
import SwiftData

/// Where first-launch onboarding is and what has been chosen so far (README §7 Onboarding).
@Observable
final class OnboardingModel {
    private(set) var step = OnboardingStep.tour
    /// `false` while going back, so the pages slide the other way.
    private(set) var movesForward = true
    var equipmentAccess = EquipmentAccess.stored {
        didSet { UserDefaults.standard.set(equipmentAccess.rawValue, forKey: AppModel.equipmentAccessKey) }
    }
    var rotationKind = StarterRotation.Kind.fullBody
    /// Entered starting weights by catalog key; a missing one starts at 0 kg.
    var weights: [String: Double] = [:]
    /// Signed in on the restore page.
    private(set) var hasRestored = false
    /// Chose Build My Own: onboarding ends in the Workout editor instead of on the ready page.
    private(set) var buildsOwnWorkout = false

    @ObservationIgnored private let appModel: AppModel
    /// Guards against a double tap moving on twice.
    @ObservationIgnored private var isAdvancing = false
    /// Started by `checkPermissions()`, so the answers are in by the time the permission pages come up.
    @ObservationIgnored private var healthCheck: Task<Bool, Never>?
    @ObservationIgnored private var alertsCheck: Task<Bool, Never>?

    init(appModel: AppModel) {
        self.appModel = appModel
    }

    /// Asks Apple Health and notifications whether they would show anything, without showing it.
    func checkPermissions() {
        guard healthCheck == nil else { return }
        let appModel = appModel
        healthCheck = Task { await appModel.healthNeedsAuthorization() }
        alertsCheck = Task { await RestNotifier.needsPermission() }
    }

    var rotation: StarterRotation {
        .make(rotationKind, for: equipmentAccess)
    }

    /// The Workouts in Rotation order once something is planned (added, restored or sent by the Watch).
    var workouts: [Workout] {
        appModel.log.workouts()
    }

    var hasCloudSync: Bool {
        appModel.cloud != nil
    }

    // MARK: - Moving on

    /// Goes to the next step that applies, or ends onboarding after the last one.
    func advance() async {
        guard !isAdvancing else { return }
        isAdvancing = true
        defer { isAdvancing = false }
        var next = OnboardingStep(rawValue: step.rawValue + 1)
        while let candidate = next, await isSkipped(candidate) {
            next = OnboardingStep(rawValue: candidate.rawValue + 1)
        }
        guard let next else {
            finish()
            return
        }
        movesForward = true
        step = next
    }

    /// From the weights back to the choice; the only way back once the tour is over.
    func goBackToStarterRotation() {
        movesForward = false
        step = .starterRotation
    }

    private func isSkipped(_ step: OnboardingStep) async -> Bool {
        switch step {
        case .tour: true
        case .restore: !hasCloudSync
        // Restored, or the Watch sent its plan meanwhile: nothing to set up.
        case .starterRotation: !workouts.isEmpty
        case .startingWeights: buildsOwnWorkout || weightedExercises.isEmpty
        case .health: !(await permissionChecks().health)
        case .restAlerts: !(await permissionChecks().alerts)
        case .ready: buildsOwnWorkout
        }
    }

    private func permissionChecks() async -> (health: Bool, alerts: Bool) {
        checkPermissions()
        return (await healthCheck?.value ?? false, await alertsCheck?.value ?? false)
    }

    // MARK: - Choices

    func restored() async {
        hasRestored = true
        // Hands the restored plan to the Watch and refreshes Strava's state.
        appModel.syncWithCloud()
        await advance()
    }

    /// Continue on the Starter Rotation page: weights next, or straight to adding a bodyweight-only plan.
    func chooseStarterRotation() async {
        buildsOwnWorkout = false
        if weightedExercises.isEmpty {
            addStarterRotation()
        }
        await advance()
    }

    func addStarterRotation() {
        guard workouts.isEmpty else { return }
        appModel.log.add(rotation, names: { String(localized: $0.workoutName) }, weights: weights)
        try? appModel.log.context.save()
    }

    func buildOwnWorkout() async {
        buildsOwnWorkout = true
        await advance()
    }

    /// Hands over to the tabs: Today, or the editor of a new, empty Workout after Build My Own.
    func finish() {
        let ownWorkout = buildsOwnWorkout && workouts.isEmpty ? appModel.log.addWorkout(named: "") : nil
        appModel.finishOnboarding(editing: ownWorkout)
    }

    // MARK: - Starter Rotation contents

    /// Exercises of the chosen Starter Rotation that use weight (not bodyweight), each once, by Workout.
    var weightedExercises: [(focus: Focus, exercises: [StarterRotation.PlannedExercise])] {
        var seen: Set<String> = []
        return rotation.workouts.compactMap { workout in
            let exercises = workout.plannedExercises.filter { planned in
                guard let entry = Self.catalog[planned.catalogKey], entry.equipment != .bodyweight else { return false }
                return seen.insert(planned.catalogKey).inserted
            }
            return exercises.isEmpty ? nil : (workout.focus, exercises)
        }
    }

    static let catalog = Dictionary(uniqueKeysWithValues: ExerciseCatalog.entries.map { ($0.key, $0) })

    /// A Starter Rotation's Planned Exercise as a row shows it, before any weight is chosen.
    static func summary(of workout: StarterRotation.Workout) -> [PlannedExerciseSummary] {
        let exercises = workout.plannedExercises
        return exercises.indices.map { index in
            let planned = exercises[index]
            let pairsWithPrevious = index > 0 && exercises[index - 1].supersetsWithNext
            return PlannedExerciseSummary(
                id: "\(workout.focus.rawValue)-\(index)-\(planned.catalogKey)",
                name: catalog[planned.catalogKey]?.name ?? planned.catalogKey,
                target: Target(sets: planned.sets, reps: planned.reps, weight: 0),
                isSuperset: planned.supersetsWithNext || pairsWithPrevious, showsWeight: false)
        }
    }
}
