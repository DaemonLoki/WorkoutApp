import Foundation
import Observation
import OnlyWorkoutCore

/// Runs a Session on whichever device is primary: forwards actions to `SessionEngine`, saves every event,
/// offers Step Up / Step Down at the right moments and ends Rest on time. Platform extras (Live Activity,
/// notifications, HealthKit, mirroring) hook in through `onChange`.
@Observable
@MainActor
public final class SessionRunner: Identifiable {
    public let session: Session
    public private(set) var engine: SessionEngine
    public private(set) var offer: SessionOffer?
    public private(set) var summary: SessionSummary?
    /// Incremented when Rest ends on its own; drives the haptic.
    public private(set) var restEndCount = 0
    /// Incremented per logged Set; drives the press haptic.
    public private(set) var loggedSetCount = 0

    /// Called after every change, so platform code can mirror, notify and update the Live Activity.
    @ObservationIgnored public var onChange: (() -> Void)?

    @ObservationIgnored private let log: TrainingLog
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var restTask: Task<Void, Never>?
    @ObservationIgnored private var layoffChecked: Set<UUID> = []
    @ObservationIgnored private var layoffDetected: Set<UUID> = []
    @ObservationIgnored private var evaluated: Set<UUID> = []
    @ObservationIgnored private var acceptedStepUps: [UUID: WeightSuggestion] = [:]

    public nonisolated var id: UUID { sessionID }
    private nonisolated let sessionID: UUID

    public init(session: Session, engine: SessionEngine, log: TrainingLog, now: @escaping () -> Date = { .now }) {
        self.session = session
        self.sessionID = session.id
        self.engine = engine
        self.log = log
        self.now = now
        for exercise in engine.exercises where !exercise.sets.isEmpty {
            layoffChecked.insert(exercise.id)
            if exercise.remainingSets == 0 { evaluated.insert(exercise.id) }
        }
        checkForLayoff()
        scheduleRestEnd()
    }

    // MARK: - Reading

    public func exercise(id: UUID) -> SessionEngine.Exercise? {
        engine.exercises.first { $0.id == id }
    }

    public func plannedExercise(for exerciseID: UUID) -> PlannedExercise? {
        session.exercises.first { $0.id == exerciseID }?.plannedExerciseID.flatMap(log.plannedExercise(id:))
    }

    public func weightStep(for exerciseID: UUID) -> Double {
        plannedExercise(for: exerciseID)?.weightStep ?? Equipment.barbell.defaultWeightStep
    }

    public func usesAddedWeight(for exerciseID: UUID) -> Bool {
        plannedExercise(for: exerciseID)?.exercise?.equipment.usesAddedWeight ?? false
    }

    // MARK: - Actions

    public func completeSet(reps: Int, weight: Double) {
        guard let completed = engine.completeSet(reps: reps, weight: weight, at: now()) else { return }
        loggedSetCount += 1
        persist()
        if completed.finishedPlannedSets {
            evaluateProgression(for: completed.exerciseID)
        }
        afterChange()
    }

    public func finishRest() {
        engine.finishRest()
        persist()
        afterChange()
    }

    public func extendRest() {
        engine.extendRest(by: PlanDefaults.restExtension)
        persist()
        afterChange()
    }

    /// Passes over the current Set of an exercise; if that was its last planned Set, progression is evaluated.
    public func skipSet(of exerciseID: UUID) {
        engine.skipSet(of: exerciseID)
        persist()
        if let exercise = exercise(id: exerciseID), exercise.remainingSets == 0, !exercise.sets.isEmpty {
            evaluateProgression(for: exerciseID)
        }
        afterChange()
    }

    public func skip(_ exerciseID: UUID) {
        engine.skip(exerciseID)
        persist()
        afterChange()
    }

    public func doLater(_ exerciseID: UUID) {
        engine.doLater(exerciseID)
        persist()
        afterChange()
    }

    public func addExtraSet(_ exerciseID: UUID) {
        engine.addExtraSet(exerciseID)
        persist()
        afterChange()
    }

    public func editSet(exerciseID: UUID, at index: Int, reps: Int, weight: Double) {
        engine.editSet(exerciseID: exerciseID, at: index, reps: reps, weight: weight)
        persist()
        if let exercise = exercise(id: exerciseID),
            exercise.sets.count(where: { !$0.isExtra }) >= exercise.target.sets
        {
            evaluateProgression(for: exerciseID)
        }
        afterChange()
    }

    public func answer(_ offer: SessionOffer, accept: Bool) {
        guard let record = log.pendingSuggestions().first(where: { $0.id == offer.id }) else {
            self.offer = nil
            afterChange()
            return
        }
        if accept {
            log.accept(record, now: now())
            if offer.suggestion.reason == .layoff {
                engine.setTargetWeight(offer.suggestion.toWeight, for: offer.exerciseID)
                persist()
            }
            if offer.suggestion.kind == .stepUp {
                acceptedStepUps[offer.exerciseID] = offer.suggestion
            }
        } else if offer.suggestion.reason == .layoff {
            // A declined Layoff Step Down only makes sense right now.
            log.dismiss(record, now: now())
        }
        // Declined Step Ups and Stall Step Downs stay pending for the Today screen.
        self.offer = nil
        afterChange()
    }

    /// Ends the Session (early if Sets remain) and prepares the Summary.
    public func finish() {
        guard summary == nil else { return }
        restTask?.cancel()
        engine.end()
        for exercise in engine.exercises where !exercise.sets.isEmpty && !evaluated.contains(exercise.id) {
            evaluateProgression(for: exercise.id, presentsOffer: false)
        }
        offer = nil
        log.finish(session, engine: engine, now: now())
        summary = makeSummary()
        onChange?()
    }

    // MARK: - Progression

    private func evaluateProgression(for exerciseID: UUID, presentsOffer: Bool = true) {
        guard let exercise = exercise(id: exerciseID), let planned = plannedExercise(for: exerciseID) else { return }
        evaluated.insert(exerciseID)
        let current = ExerciseResult(
            date: session.startedAt, target: exercise.target, sets: exercise.sets, plannedExerciseID: planned.id,
            skippedSets: exercise.skippedSets)
        let history = log.history(plannedExerciseID: planned.id) + [current]
        guard
            let suggestion = Progression.suggestion(
                history: history, currentWeight: planned.weight, weightStep: planned.weightStep)
        else {
            log.supersedePending(for: planned.id, now: now())
            return
        }
        let record = log.offer(suggestion, for: planned.id, from: session.id, now: now())
        if presentsOffer {
            offer = SessionOffer(
                id: record.id, exerciseID: exerciseID, exerciseName: exercise.name, suggestion: suggestion)
        }
    }

    /// Offers a Step Down before the first Set of an exercise coming back after a Layoff.
    private func checkForLayoff() {
        guard offer == nil, let prompt = engine.currentSet, let exercise = exercise(id: prompt.exerciseID),
            exercise.sets.isEmpty, !layoffChecked.contains(exercise.id),
            let planned = plannedExercise(for: exercise.id)
        else { return }
        layoffChecked.insert(exercise.id)
        guard
            let suggestion = Progression.layoffSuggestion(
                lastPerformed: log.lastPerformed(plannedExerciseID: planned.id), now: now(),
                currentWeight: planned.weight, weightStep: planned.weightStep)
        else { return }
        layoffDetected.insert(exercise.id)
        let record = log.offer(suggestion, for: planned.id, from: session.id, now: now())
        offer = SessionOffer(
            id: record.id, exerciseID: exercise.id, exerciseName: exercise.name, suggestion: suggestion)
    }

    // MARK: - Plumbing

    private func afterChange() {
        checkForLayoff()
        scheduleRestEnd()
        onChange?()
    }

    private func persist() {
        log.save(engine, to: session, now: now())
    }

    private func scheduleRestEnd() {
        restTask?.cancel()
        guard let rest = engine.rest else { return }
        restTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(0, rest.endsAt.timeIntervalSinceNow)))
            guard !Task.isCancelled, let self, self.engine.rest == rest else { return }
            self.engine.finishRest()
            self.restEndCount += 1
            self.persist()
            self.afterChange()
        }
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
