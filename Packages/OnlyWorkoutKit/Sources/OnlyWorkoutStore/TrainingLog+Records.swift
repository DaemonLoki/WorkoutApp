import Foundation
import OnlyWorkoutCore
import SwiftData

extension TrainingLog {
    // MARK: - Export

    /// The whole plan: Exercises, Workouts, Planned Exercises and suggestions, tombstones included.
    public func exportPlan() -> RecordBatch {
        var batch = RecordBatch()
        batch.exercises = fetchAll(Exercise.self).map(ExerciseRecord.init)
        batch.workouts = fetchAll(Workout.self).map(WorkoutRecord.init)
        batch.plannedExercises = fetchAll(PlannedExercise.self).map(PlannedExerciseRecord.init)
        batch.suggestions = fetchAll(ProgressionSuggestion.self).map(SuggestionRecord.init)
        return batch
    }

    /// The given Sessions with their Session Exercises and Sets.
    public func exportSessions(_ sessions: [Session]) -> RecordBatch {
        var batch = RecordBatch()
        batch.sessions = sessions.map(SessionRecord.init)
        let entries = sessions.flatMap(\.exercises)
        batch.sessionExercises = entries.map(SessionExerciseRecord.init)
        batch.sets = entries.flatMap(\.sets).map(SetRecord.init)
        return batch
    }

    /// How long a deleted Watch-recorded Session keeps riding along in the Watch snapshot,
    /// so the Watch gets to delete its Health workout even if it's away for a while.
    public static let watchTombstoneLifetime: TimeInterval = 30 * 86_400

    /// What the Watch needs to run Sessions offline: the plan plus, per Planned Exercise, its last
    /// `Progression.stallSessionCount` Sessions (enough for Target Hit, Stall and Layoff). Also the
    /// recently deleted Sessions the Watch recorded: only the Watch can delete their Health workouts.
    public func watchSnapshot(now: Date = .now) -> RecordBatch {
        var batch = exportPlan()
        var sessions: [UUID: Session] = [:]
        for planned in fetchAll(PlannedExercise.self) where planned.deletedAt == nil {
            for entry in performed(plannedExerciseID: planned.id).suffix(Progression.stallSessionCount) {
                if let session = entry.session { sessions[session.id] = session }
            }
        }
        let cutoff = now.addingTimeInterval(-Self.watchTombstoneLifetime)
        for session in healthWorkoutsToDelete(recordedOn: .watch) where session.deletedAt ?? .distantPast > cutoff {
            sessions[session.id] = session
        }
        batch.merge(exportSessions(Array(sessions.values)))
        return batch
    }

    // MARK: - Cloud

    /// Every record whose current version the cloud doesn't have yet, tombstones included.
    public func pendingPush() -> RecordBatch {
        var batch = RecordBatch()
        batch.exercises = pending(Exercise.self).map(ExerciseRecord.init)
        batch.workouts = pending(Workout.self).map(WorkoutRecord.init)
        batch.plannedExercises = pending(PlannedExercise.self).map(PlannedExerciseRecord.init)
        batch.sessions = pending(Session.self).map(SessionRecord.init)
        batch.sessionExercises = pending(SessionExercise.self).map(SessionExerciseRecord.init)
        batch.sets = pending(SetEntry.self).map(SetRecord.init)
        batch.suggestions = pending(ProgressionSuggestion.self).map(SuggestionRecord.init)
        return batch
    }

    /// Records that `sync_push` accepted; a record edited since it was exported stays pending.
    public func markPushed(_ batch: RecordBatch) {
        markSynced(batch.exercises, Exercise.self)
        markSynced(batch.workouts, Workout.self)
        markSynced(batch.plannedExercises, PlannedExercise.self)
        markSynced(batch.sessions, Session.self)
        markSynced(batch.sessionExercises, SessionExercise.self)
        markSynced(batch.sets, SetEntry.self)
        markSynced(batch.suggestions, ProgressionSuggestion.self)
        try? context.save()
    }

    /// After signing out: the next account starts with nothing, so every record is owed again.
    public func forgetSyncedVersions() {
        forget(Exercise.self)
        forget(Workout.self)
        forget(PlannedExercise.self)
        forget(Session.self)
        forget(SessionExercise.self)
        forget(SetEntry.self)
        forget(ProgressionSuggestion.self)
        try? context.save()
    }

    private func forget<Model: PersistentModel & IdentifiedRecord>(_ type: Model.Type) {
        for model in fetchAll(Model.self) { model.syncedUpdatedAt = nil }
    }

    private func pending<Model: PersistentModel & IdentifiedRecord>(_ type: Model.Type) -> [Model] {
        fetchAll(Model.self).filter { $0.syncedUpdatedAt != $0.updatedAt }
    }

    private func markSynced<Model: PersistentModel & IdentifiedRecord, Record: SyncRecord>(
        _ records: [Record], _ type: Model.Type
    ) {
        let versions = Dictionary(records.map { ($0.id, $0.updatedAt) }, uniquingKeysWith: max)
        for model in fetchAll(Model.self) {
            if let version = versions[model.id] { model.syncedUpdatedAt = version }
        }
    }

    // MARK: - Apply

    /// Merges records from another device or the cloud: per record, the newer `updatedAt` wins (ADR-0001).
    public func apply(_ batch: RecordBatch, fromCloud: Bool = false) {
        let exercises = upsert(
            batch.exercises, fromCloud: fromCloud,
            make: { Exercise(id: $0.id, name: $0.name, equipment: .machine, muscleGroups: []) },
            write: { record, model in record.write(to: model) })

        let workouts = upsert(
            batch.workouts, fromCloud: fromCloud,
            make: { Workout(id: $0.id, name: $0.name, rotationIndex: $0.rotationIndex) },
            write: { record, model in record.write(to: model) })

        upsert(
            batch.plannedExercises, fromCloud: fromCloud,
            make: { record in
                // A Planned Exercise can't exist without its Exercise; skip it until the Exercise arrives.
                record.exerciseID.flatMap { exercises[$0] }.map {
                    PlannedExercise(id: record.id, exercise: $0, position: record.position)
                }
            },
            write: { record, model in
                record.write(to: model)
                model.exercise = record.exerciseID.flatMap { exercises[$0] }
                model.workout = record.workoutID.flatMap { workouts[$0] }
            })

        let sessions = upsert(
            batch.sessions, fromCloud: fromCloud,
            make: { Session(id: $0.id, workoutID: $0.workoutID, workoutName: $0.workoutName, startedAt: $0.startedAt) },
            write: { record, model in record.write(to: model) })

        let sessionExercises = upsert(
            batch.sessionExercises, fromCloud: fromCloud,
            make: { record in
                SessionExercise(
                    id: record.id, exerciseID: record.exerciseID, plannedExerciseID: record.plannedExerciseID,
                    exerciseName: record.exerciseName, position: record.position, supersetID: record.supersetID,
                    target: Target(sets: record.targetSets, reps: record.targetReps, weight: record.targetWeight),
                    now: record.createdAt)
            },
            write: { record, model in
                record.write(to: model)
                model.session = record.sessionID.flatMap { sessions[$0] }
            })

        upsert(
            batch.sets, fromCloud: fromCloud,
            make: { record in
                SetEntry(
                    id: record.id, number: record.number, reps: record.reps, weight: record.weight,
                    isExtra: record.isExtra, completedAt: record.completedAt)
            },
            write: { record, model in
                record.write(to: model)
                model.sessionExercise = record.sessionExerciseID.flatMap { sessionExercises[$0] }
            })

        upsert(
            batch.suggestions, fromCloud: fromCloud,
            make: { record in
                ProgressionSuggestion(
                    id: record.id, plannedExerciseID: record.plannedExerciseID,
                    suggestion: WeightSuggestion(
                        kind: .init(rawValue: record.kind) ?? .stepUp,
                        reason: .init(rawValue: record.reason) ?? .targetHit,
                        fromWeight: record.fromWeight, toWeight: record.toWeight),
                    sourceSessionID: record.sourceSessionID, now: record.createdAt)
            },
            write: { record, model in record.write(to: model) })

        try? context.save()
    }

    /// Inserts or overwrites the winning records and returns every model of the type by id,
    /// so children can link to their parents. Winners from the cloud are already synced.
    @discardableResult
    private func upsert<Model: PersistentModel & IdentifiedRecord, Record: SyncRecord>(
        _ records: [Record], fromCloud: Bool, make: (Record) -> Model?, write: (Record, Model) -> Void
    ) -> [UUID: Model] {
        var models = Dictionary(fetchAll(Model.self).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let winners = RecordMerger.winners(incoming: records, existing: models.mapValues(\.updatedAt))
        for record in winners {
            let model: Model
            if let existing = models[record.id] {
                model = existing
            } else if let created = make(record) {
                model = created
                context.insert(model)
                models[record.id] = model
            } else {
                continue
            }
            write(record, model)
            if fromCloud { model.syncedUpdatedAt = record.updatedAt }
        }
        return models
    }

    func fetchAll<Model: PersistentModel>(_ type: Model.Type) -> [Model] {
        (try? context.fetch(FetchDescriptor<Model>())) ?? []
    }
}

/// Stored models that carry the sync identity and clock.
protocol IdentifiedRecord: AnyObject {
    var id: UUID { get }
    var updatedAt: Date { get }
    var syncedUpdatedAt: Date? { get set }
}

extension Exercise: IdentifiedRecord {}
extension Workout: IdentifiedRecord {}
extension PlannedExercise: IdentifiedRecord {}
extension Session: IdentifiedRecord {}
extension SessionExercise: IdentifiedRecord {}
extension SetEntry: IdentifiedRecord {}
extension ProgressionSuggestion: IdentifiedRecord {}
