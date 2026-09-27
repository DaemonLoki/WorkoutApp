import Foundation
import OnlyWorkoutStore
import SwiftData

/// Shared fetch predicates so every screen agrees on what is "live".
enum Queries {
    static var liveWorkouts: FetchDescriptor<Workout> {
        FetchDescriptor(predicate: #Predicate { $0.deletedAt == nil }, sortBy: [SortDescriptor(\.rotationIndex)])
    }

    static var pendingSuggestions: FetchDescriptor<ProgressionSuggestion> {
        FetchDescriptor(
            predicate: #Predicate { $0.statusRaw == "pending" && $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
    }

    static var liveSessions: FetchDescriptor<Session> {
        FetchDescriptor(
            predicate: #Predicate { $0.deletedAt == nil }, sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
    }

    static var liveExercises: FetchDescriptor<Exercise> {
        FetchDescriptor(
            predicate: #Predicate { $0.deletedAt == nil && $0.archivedAt == nil }, sortBy: [SortDescriptor(\.name)])
    }

    static var allExercises: FetchDescriptor<Exercise> {
        FetchDescriptor(sortBy: [SortDescriptor(\.name)])
    }

    static var liveSessionExercises: FetchDescriptor<SessionExercise> {
        FetchDescriptor(predicate: #Predicate { $0.deletedAt == nil })
    }
}
