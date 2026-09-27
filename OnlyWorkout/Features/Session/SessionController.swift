import Foundation
import Observation
import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutLiveActivity
import OnlyWorkoutStore

/// Runs the Session on the iPhone: forwards user actions to `SessionEngine`, persists every event,
/// offers Step Up / Step Down at the right moments and keeps Rest, notifications and the Live Activity in step.
@Observable
final class SessionController: Identifiable {
    /// A Step Up or Step Down card waiting for an answer.
    struct Offer: Identifiable, Equatable {
        let id: UUID
        let exerciseID: UUID
        let exerciseName: String
        let suggestion: WeightSuggestion
    }

    let session: Session
    private(set) var engine: SessionEngine
    private(set) var offer: Offer?
    private(set) var summary: SessionSummary?
    /// Incremented when Rest ends on its own; drives the haptic.
    private(set) var restEndCount = 0
    /// Incremented per logged Set; drives the press haptic.
    private(set) var loggedSetCount = 0

    @ObservationIgnored private let log: TrainingLog
    @ObservationIgnored private let liveActivity = LiveActivityController()
    @ObservationIgnored private let restNotifier = RestNotifier()
    @ObservationIgnored private var restTask: Task<Void, Never>?
    @ObservationIgnored private var layoffChecked: Set<UUID> = []
    @ObservationIgnored private var layoffDetected: Set<UUID> = []
    @ObservationIgnored private var evaluated: Set<UUID> = []
    @ObservationIgnored private var acceptedStepUps: [UUID: WeightSuggestion] = [:]

    var id: UUID { session.id }

    init(session: Session, engine: SessionEngine, log: TrainingLog) {
        self.session = session
        self.engine = engine
        self.log = log
        for exercise in engine.exercises where !exercise.sets.isEmpty {
            layoffChecked.insert(exercise.id)
            if exercise.remainingSets == 0 { evaluated.insert(exercise.id) }
        }
        restNotifier.requestAuthorization()
        liveActivity.start(workoutName: session.workoutName, state: liveActivityState)
        checkForLayoff()
        scheduleRestEnd()
    }

    // MARK: - Reading

    var currentExercise: SessionEngine.Exercise? {
        engine.currentSet.flatMap { exercise(id: $0.exerciseID) }
    }

    func exercise(id: UUID) -> SessionEngine.Exercise? {
        engine.exercises.first { $0.id == id }
    }

    func plannedExercise(for exerciseID: UUID) -> PlannedExercise? {
        entry(for: exerciseID)?.plannedExerciseID.flatMap(log.plannedExercise(id:))
    }

    func weightStep(for exerciseID: UUID) -> Double {
        plannedExercise(for: exerciseID)?.weightStep ?? 2.5
    }

    var hasRemainingSets: Bool {
        !engine.isComplete
    }

    // MARK: - Actions

    func completeSet(reps: Int, weight: Double) {
        guard let completed = engine.completeSet(reps: reps, weight: weight, at: .now) else { return }
        loggedSetCount += 1
        persist()
        if completed.finishedPlannedSets {
            evaluateProgression(for: completed.exerciseID)
        }
        afterChange()
    }

    func finishRest() {
        engine.finishRest()
        persist()
        afterChange()
    }

    func extendRest() {
        engine.extendRest(by: PlanDefaults.restExtension)
        persist()
        afterChange()
    }

    func skip(_ exerciseID: UUID) {
        engine.skip(exerciseID)
        persist()
        afterChange()
    }

    func doLater(_ exerciseID: UUID) {
        engine.doLater(exerciseID)
        persist()
        afterChange()
    }

    func addExtraSet(_ exerciseID: UUID) {
        engine.addExtraSet(exerciseID)
        persist()
        afterChange()
    }

    func editSet(exerciseID: UUID, at index: Int, reps: Int, weight: Double) {
        engine.editSet(exerciseID: exerciseID, at: index, reps: reps, weight: weight)
        persist()
        if let exercise = exercise(id: exerciseID), exercise.sets.count(where: { !$0.isExtra }) >= exercise.target.sets
        {
            evaluateProgression(for: exerciseID)
        }
        afterChange()
    }

    func answer(_ offer: Offer, accept: Bool) {
        guard let record = log.pendingSuggestions().first(where: { $0.id == offer.id }) else {
            self.offer = nil
            return
        }
        if accept {
            log.accept(record)
            if offer.suggestion.reason == .layoff {
                engine.setTargetWeight(offer.suggestion.toWeight, for: offer.exerciseID)
                persist()
            }
            if offer.suggestion.kind == .stepUp {
                acceptedStepUps[offer.exerciseID] = offer.suggestion
            }
        } else if offer.suggestion.reason == .layoff {
            // A declined Layoff Step Down only makes sense right now.
            log.dismiss(record)
        }
        // Declined Step Ups and Stall Step Downs stay pending for the Today screen.
        self.offer = nil
        afterChange()
    }

    /// Ends the Session (early if Sets remain) and prepares the Summary.
    func finish() {
        restTask?.cancel()
        restNotifier.cancel()
        engine.end()
        for exercise in engine.exercises where !exercise.sets.isEmpty && !evaluated.contains(exercise.id) {
            evaluateProgression(for: exercise.id, presentsOffer: false)
        }
        log.finish(session, engine: engine)
        summary = makeSummary()
        liveActivity.end()
    }

    // MARK: - Progression

    private func evaluateProgression(for exerciseID: UUID, presentsOffer: Bool = true) {
        guard let exercise = exercise(id: exerciseID), let planned = plannedExercise(for: exerciseID) else { return }
        evaluated.insert(exerciseID)
        let current = ExerciseResult(
            date: session.startedAt, target: exercise.target, sets: exercise.sets, plannedExerciseID: planned.id)
        let history = log.history(plannedExerciseID: planned.id) + [current]
        guard
            let suggestion = Progression.suggestion(
                history: history, currentWeight: planned.weight, weightStep: planned.weightStep)
        else {
            log.supersedePending(for: planned.id)
            return
        }
        let record = log.offer(suggestion, for: planned.id, from: session.id)
        if presentsOffer {
            offer = Offer(id: record.id, exerciseID: exerciseID, exerciseName: exercise.name, suggestion: suggestion)
        }
    }

    /// Offers a Step Down before the first Set of an exercise coming back after a Layoff.
    private func checkForLayoff() {
        guard offer == nil, let exercise = currentExercise, exercise.sets.isEmpty,
            !layoffChecked.contains(exercise.id), let planned = plannedExercise(for: exercise.id)
        else { return }
        layoffChecked.insert(exercise.id)
        guard
            let suggestion = Progression.layoffSuggestion(
                lastPerformed: log.lastPerformed(plannedExerciseID: planned.id), now: .now,
                currentWeight: planned.weight, weightStep: planned.weightStep)
        else { return }
        layoffDetected.insert(exercise.id)
        let record = log.offer(suggestion, for: planned.id, from: session.id)
        offer = Offer(id: record.id, exerciseID: exercise.id, exerciseName: exercise.name, suggestion: suggestion)
    }

    // MARK: - Plumbing

    private func afterChange() {
        checkForLayoff()
        scheduleRestEnd()
        liveActivity.update(state: liveActivityState)
    }

    private func persist() {
        log.save(engine, to: session)
    }

    private func entry(for exerciseID: UUID) -> SessionExercise? {
        session.exercises.first { $0.id == exerciseID }
    }

    private func scheduleRestEnd() {
        restTask?.cancel()
        guard let rest = engine.rest else {
            restNotifier.cancel()
            return
        }
        restNotifier.schedule(at: rest.endsAt, next: nextSetDescription)
        restTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(0, rest.endsAt.timeIntervalSinceNow)))
            guard !Task.isCancelled, let self, self.engine.rest == rest else { return }
            self.engine.finishRest()
            self.restEndCount += 1
            self.persist()
            self.afterChange()
        }
    }

    /// e.g. "Lat Pulldown · Set 2 of 3 · 12 × 55 kg"
    var nextSetDescription: String? {
        guard let prompt = engine.currentSet, let exercise = exercise(id: prompt.exerciseID) else { return nil }
        return String(
            localized: .nextSetDescription(
                exercise.name, prompt.setNumber, prompt.totalSets, prompt.reps, prompt.weight.kilograms))
    }

    private var liveActivityState: LiveActivityController.State {
        guard let prompt = engine.currentSet, let exercise = exercise(id: prompt.exerciseID) else {
            return .init(
                exerciseName: session.workoutName, setLabel: String(localized: .allSetsDone), shortSetLabel: "✓",
                detail: "",
                restInterval: nil, nextUp: nil)
        }
        return .init(
            exerciseName: exercise.name,
            setLabel: String(localized: .setProgress(prompt.setNumber, prompt.totalSets)),
            shortSetLabel: "\(prompt.setNumber)/\(prompt.totalSets)",
            detail: String(localized: .repsAtWeight(prompt.reps, prompt.weight.kilograms)),
            restInterval: engine.rest.map { $0.startedAt...$0.endsAt },
            nextUp: engine.rest == nil ? nil : nextSetDescription)
    }

    private func makeSummary() -> SessionSummary {
        let entries = session.orderedExercises.filter { !$0.orderedSets.isEmpty }
        let recaps = entries.map { entry in
            ExerciseRecap(
                exerciseName: entry.exerciseName, result: entry.result,
                previousBest: log.previousBest(exerciseID: entry.exerciseID, excluding: session.id),
                acceptedStepUp: acceptedStepUps[entry.id],
                firstRecorded: log.firstRecorded(exerciseID: entry.exerciseID),
                cameBackAfterLayoff: layoffDetected.contains(entry.id))
        }
        return SessionSummary(
            sessionID: session.id, workoutName: session.workoutName, duration: session.duration ?? 0,
            setCount: session.allSets.count, volume: session.totalVolume, events: Motivation.events(for: recaps))
    }
}
