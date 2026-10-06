import Foundation
import OnlyWorkoutStore

/// The synced tables as `sync_push` takes them and `sync_pull` returns them; in snake_case, the
/// property names are the Postgres table names.
struct CloudTables: Codable {
    var exercises: [ExerciseRecord] = []
    var workouts: [WorkoutRecord] = []
    var plannedExercises: [PlannedExerciseRecord] = []
    var sessions: [SessionRecord] = []
    var sessionExercises: [SessionExerciseRecord] = []
    var sets: [SetRecord] = []
    var progressionSuggestions: [SuggestionRecord] = []
    /// Pull only: the newest server change, where the next pull continues.
    var cursor: Date?

    /// Health data stays on the device (README §11).
    init(_ batch: RecordBatch) {
        exercises = batch.exercises
        workouts = batch.workouts
        plannedExercises = batch.plannedExercises
        sessions = batch.sessions.map { session in
            var session = session
            session.healthWorkoutID = nil
            return session
        }
        sessionExercises = batch.sessionExercises
        sets = batch.sets
        progressionSuggestions = batch.suggestions
    }

    var batch: RecordBatch {
        var batch = RecordBatch()
        batch.exercises = exercises
        batch.workouts = workouts
        batch.plannedExercises = plannedExercises
        batch.sessions = sessions
        batch.sessionExercises = sessionExercises
        batch.sets = sets
        batch.suggestions = progressionSuggestions
        return batch
    }
}
