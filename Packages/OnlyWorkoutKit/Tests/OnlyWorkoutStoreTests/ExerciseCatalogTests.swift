import Foundation
import SwiftData
import Testing

@testable import OnlyWorkoutStore

@Suite("ExerciseCatalog")
@MainActor
struct ExerciseCatalogTests {
    @Test func seedingTwiceCreatesEachCatalogExerciseOnceWithDeterministicIDs() throws {
        let container = try StoreContainer.make(inMemory: true)
        let context = container.mainContext

        try ExerciseCatalog.seed(into: context)
        try ExerciseCatalog.seed(into: context)

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == ExerciseCatalog.entries.count)
        #expect(exercises.count == 44)

        // Reference value: Python uuid5(uuid5(NAMESPACE_DNS, "onlyworkout.stefanblos.com"), "back-squat").
        let squat = exercises.first { $0.catalogKey == "back-squat" }
        #expect(squat?.id == UUID(uuidString: "f61458c1-a06a-5047-9e6c-17d73b36ca97"))
        #expect(squat?.name == "Back Squat")
        #expect(squat?.muscleGroups == [.quads, .glutes])
    }
}
