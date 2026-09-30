import Foundation

/// Plain, `Codable` copies of stored records, linked by id, for moving data between devices (README §8, §10).
public struct RecordBatch: Codable, Equatable, Sendable {
    public var exercises: [ExerciseRecord] = []
    public var workouts: [WorkoutRecord] = []
    public var plannedExercises: [PlannedExerciseRecord] = []
    public var sessions: [SessionRecord] = []
    public var sessionExercises: [SessionExerciseRecord] = []
    public var sets: [SetRecord] = []
    public var suggestions: [SuggestionRecord] = []

    public init() {}

    public var isEmpty: Bool {
        exercises.isEmpty && workouts.isEmpty && plannedExercises.isEmpty && sessions.isEmpty
            && sessionExercises.isEmpty && sets.isEmpty && suggestions.isEmpty
    }

    public mutating func merge(_ other: RecordBatch) {
        exercises += other.exercises
        workouts += other.workouts
        plannedExercises += other.plannedExercises
        sessions += other.sessions
        sessionExercises += other.sessionExercises
        sets += other.sets
        suggestions += other.suggestions
    }
}
