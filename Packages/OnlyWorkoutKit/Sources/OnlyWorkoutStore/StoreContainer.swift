import Foundation
import SwiftData

/// Builds the app's SwiftData container.
public enum StoreContainer {
    public static let models: [any PersistentModel.Type] = [
        Exercise.self, Workout.self, PlannedExercise.self, Session.self, SessionExercise.self, SetEntry.self,
        ProgressionSuggestion.self,
    ]

    public static func make(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: Schema(models), configurations: configuration)
    }
}
