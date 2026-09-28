import Foundation
import OnlyWorkoutCore
import SwiftData

/// Reads and writes the training history. Keeps SwiftData details out of views and feeds the pure rules in
/// `OnlyWorkoutCore` with plain values.
@MainActor
public struct TrainingLog {
    public let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Plan

    /// Live Workouts in Rotation order.
    public func workouts() -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.deletedAt == nil }, sortBy: [SortDescriptor(\.rotationIndex)])
        return (try? context.fetch(descriptor)) ?? []
    }

    public func nextUp(in workouts: [Workout]) -> Workout? {
        let nextID = Rotation.nextUp(in: workouts.map(\.id), lastStarted: lastStartedSession()?.workoutID)
        return workouts.first { $0.id == nextID }
    }

    public func plannedExercise(id: UUID) -> PlannedExercise? {
        let descriptor = FetchDescriptor<PlannedExercise>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    /// Creates a Workout at the end of the Rotation.
    public func addWorkout(named name: String, now: Date = .now) -> Workout {
        let workout = Workout(name: name, rotationIndex: (workouts().last?.rotationIndex ?? -1) + 1, now: now)
        context.insert(workout)
        return workout
    }

    public func add(_ exercise: Exercise, to workout: Workout, now: Date = .now) -> PlannedExercise {
        let position = (workout.orderedPlannedExercises.last?.position ?? -1) + 1
        let planned = PlannedExercise(exercise: exercise, position: position, now: now)
        context.insert(planned)
        planned.workout = workout
        workout.updatedAt = now
        return planned
    }

    /// Saves a new order for the Rotation.
    public func reorder(_ workouts: [Workout], now: Date = .now) {
        for (index, workout) in workouts.enumerated() where workout.rotationIndex != index {
            workout.rotationIndex = index
            workout.updatedAt = now
        }
    }

    public func delete(_ workout: Workout, now: Date = .now) {
        workout.deletedAt = now
        workout.updatedAt = now
        for planned in workout.plannedExercises where planned.deletedAt == nil {
            delete(planned, now: now)
        }
    }

    public func delete(_ planned: PlannedExercise, now: Date = .now) {
        planned.deletedAt = now
        planned.updatedAt = now
        if let partner = supersetPartner(of: planned) {
            partner.supersetID = nil
            partner.updatedAt = now
        }
        planned.supersetID = nil
    }

    public func supersetPartner(of planned: PlannedExercise) -> PlannedExercise? {
        guard let supersetID = planned.supersetID else { return nil }
        return planned.workout?.orderedPlannedExercises.first { $0.supersetID == supersetID && $0.id != planned.id }
    }

    /// Custom Exercises with history are archived so past Sessions keep their meaning; others are deleted.
    public func delete(_ exercise: Exercise, now: Date = .now) {
        let exerciseID = exercise.id
        let hasHistory =
            ((try? context.fetchCount(
                FetchDescriptor<SessionExercise>(predicate: #Predicate { $0.exerciseID == exerciseID }))) ?? 0) > 0
        if hasHistory {
            exercise.archivedAt = now
        } else {
            exercise.deletedAt = now
        }
        exercise.updatedAt = now
    }

    // MARK: - History

    public func lastStartedSession() -> Session? {
        var descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.deletedAt == nil }, sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// Finished Sessions recorded on a device since a date, newest first.
    public func finishedSessions(recordedOn device: Session.Device, since date: Date) -> [Session] {
        let raw = device.rawValue
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.recordedOnRaw == raw && $0.endedAt != nil && $0.startedAt >= date },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    public func inProgressSession() -> Session? {
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.deletedAt == nil && $0.endedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        return try? context.fetch(descriptor).first
    }

    /// Performed (not skipped) Session Exercises of finished, live Sessions, oldest first.
    public func performed(plannedExerciseID: UUID) -> [SessionExercise] {
        let descriptor = FetchDescriptor<SessionExercise>(
            predicate: #Predicate { $0.plannedExerciseID == plannedExerciseID && $0.deletedAt == nil })
        return performed(in: (try? context.fetch(descriptor)) ?? [])
    }

    public func performed(exerciseID: UUID) -> [SessionExercise] {
        let descriptor = FetchDescriptor<SessionExercise>(
            predicate: #Predicate { $0.exerciseID == exerciseID && $0.deletedAt == nil })
        return performed(in: (try? context.fetch(descriptor)) ?? [])
    }

    private func performed(in exercises: [SessionExercise]) -> [SessionExercise] {
        exercises
            .filter { entry in
                guard let session = entry.session else { return false }
                return session.deletedAt == nil && session.endedAt != nil && entry.status != .skipped
                    && !entry.orderedSets.isEmpty
            }
            .sorted { ($0.session?.startedAt ?? $0.createdAt) < ($1.session?.startedAt ?? $1.createdAt) }
    }

    /// Progression input for a Planned Exercise, oldest first.
    public func history(plannedExerciseID: UUID) -> [ExerciseResult] {
        performed(plannedExerciseID: plannedExerciseID).map(\.result)
    }

    public func lastPerformed(plannedExerciseID: UUID) -> Date? {
        performed(plannedExerciseID: plannedExerciseID).last?.session?.startedAt
    }

    /// Best Set of an Exercise across finished Sessions other than `sessionID`.
    public func previousBest(exerciseID: UUID, excluding sessionID: UUID) -> LoggedSet? {
        performed(exerciseID: exerciseID)
            .filter { $0.session?.id != sessionID }
            .flatMap(\.orderedSets)
            .map(\.loggedSet)
            .max { $1.beats($0) }
    }

    /// The earliest Target weight recorded for an Exercise.
    public func firstRecorded(exerciseID: UUID) -> (date: Date, weight: Double)? {
        guard let first = performed(exerciseID: exerciseID).first, let date = first.session?.startedAt else {
            return nil
        }
        return (date, first.targetWeight)
    }

    // MARK: - Sessions

    /// Creates a Session snapshotting the Workout, plus the engine that will run it.
    public func startSession(_ workout: Workout, recordedOn device: Session.Device = .phone, now: Date = .now)
        -> (Session, SessionEngine)
    {
        let session = Session(workoutID: workout.id, workoutName: workout.name, startedAt: now, recordedOn: device)
        context.insert(session)

        var engineExercises: [SessionEngine.Exercise] = []
        for (position, planned) in workout.orderedPlannedExercises.enumerated() {
            guard let exercise = planned.exercise else { continue }
            let entry = SessionExercise(
                exerciseID: exercise.id, plannedExerciseID: planned.id, exerciseName: exercise.name,
                position: position, supersetID: planned.supersetID, target: planned.target, now: now)
            context.insert(entry)
            entry.session = session
            engineExercises.append(
                SessionEngine.Exercise(
                    id: entry.id, name: exercise.name, target: planned.target, restSeconds: planned.restSeconds,
                    supersetID: planned.supersetID))
        }

        let engine = SessionEngine(exercises: engineExercises)
        save(engine, to: session, now: now)
        return (session, engine)
    }

    /// Mirrors the engine's state into the Session's records after every event.
    public func save(_ engine: SessionEngine, to session: Session, now: Date = .now) {
        let entries = Dictionary(uniqueKeysWithValues: session.exercises.map { ($0.id, $0) })
        for (position, exercise) in engine.exercises.enumerated() {
            guard let entry = entries[exercise.id] else { continue }
            var changed = false
            func update<Value: Equatable>(_ keyPath: ReferenceWritableKeyPath<SessionExercise, Value>, _ value: Value) {
                if entry[keyPath: keyPath] != value {
                    entry[keyPath: keyPath] = value
                    changed = true
                }
            }
            update(\.position, position)
            update(\.targetWeight, exercise.target.weight)
            update(\.statusRaw, exercise.status.rawValue)

            let stored = entry.orderedSets
            for (index, set) in exercise.sets.enumerated() {
                if index < stored.count {
                    let record = stored[index]
                    if record.reps != set.reps || record.weight != set.weight {
                        record.reps = set.reps
                        record.weight = set.weight
                        record.updatedAt = now
                    }
                } else {
                    let record = SetEntry(
                        number: index + 1, reps: set.reps, weight: set.weight, isExtra: set.isExtra, completedAt: now)
                    context.insert(record)
                    record.sessionExercise = entry
                    changed = true
                }
            }
            if changed { entry.updatedAt = now }
        }
        session.engineState = try? JSONEncoder().encode(engine)
        session.updatedAt = now
        try? context.save()
    }

    public func restoreEngine(of session: Session) -> SessionEngine? {
        session.engineState.flatMap { try? JSONDecoder().decode(SessionEngine.self, from: $0) }
    }

    public func finish(_ session: Session, engine: SessionEngine, now: Date = .now) {
        save(engine, to: session, now: now)
        session.endedAt = now
        session.engineState = nil
        session.updatedAt = now
        try? context.save()
    }

    /// Remembers the Apple Health workout saved for a Session.
    public func attachHealthWorkout(_ id: UUID?, to session: Session, now: Date = .now) {
        guard let id else { return }
        session.healthWorkoutID = id
        session.updatedAt = now
        try? context.save()
    }

    public func delete(_ session: Session, now: Date = .now) {
        session.deletedAt = now
        session.updatedAt = now
        for entry in session.exercises {
            entry.deletedAt = now
            entry.updatedAt = now
            for set in entry.sets {
                set.deletedAt = now
                set.updatedAt = now
            }
        }
        try? context.save()
    }

    /// Corrects a Set of a finished Session.
    public func update(_ set: SetEntry, reps: Int, weight: Double, now: Date = .now) {
        set.reps = reps
        set.weight = weight
        set.updatedAt = now
        try? context.save()
    }

    // MARK: - Suggestions

    public func pendingSuggestions() -> [ProgressionSuggestion] {
        let pending = ProgressionSuggestion.Status.pending.rawValue
        let descriptor = FetchDescriptor<ProgressionSuggestion>(
            predicate: #Predicate { $0.statusRaw == pending && $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Records a new suggestion as the single pending one for its Planned Exercise.
    @discardableResult
    public func offer(
        _ suggestion: WeightSuggestion, for plannedExerciseID: UUID, from sessionID: UUID?, now: Date = .now
    ) -> ProgressionSuggestion {
        supersedePending(for: plannedExerciseID, now: now)
        let record = ProgressionSuggestion(
            plannedExerciseID: plannedExerciseID, suggestion: suggestion, sourceSessionID: sessionID, now: now)
        context.insert(record)
        try? context.save()
        return record
    }

    /// A newer Session of the Planned Exercise replaces whatever was still waiting.
    public func supersedePending(for plannedExerciseID: UUID, now: Date = .now) {
        for suggestion in pendingSuggestions() where suggestion.plannedExerciseID == plannedExerciseID {
            resolve(suggestion, as: .superseded, now: now)
        }
    }

    public func accept(_ suggestion: ProgressionSuggestion, now: Date = .now) {
        if let planned = plannedExercise(id: suggestion.plannedExerciseID) {
            planned.weight = suggestion.toWeight
            planned.updatedAt = now
        }
        resolve(suggestion, as: .accepted, now: now)
        try? context.save()
    }

    public func dismiss(_ suggestion: ProgressionSuggestion, now: Date = .now) {
        resolve(suggestion, as: .dismissed, now: now)
        try? context.save()
    }

    private func resolve(_ suggestion: ProgressionSuggestion, as status: ProgressionSuggestion.Status, now: Date) {
        suggestion.status = status
        suggestion.resolvedAt = now
        suggestion.updatedAt = now
    }
}
