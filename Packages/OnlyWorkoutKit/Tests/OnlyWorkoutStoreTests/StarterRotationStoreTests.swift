import Foundation
import OnlyWorkoutCore
import SwiftData
import Testing

@testable import OnlyWorkoutStore

/// Adding a Starter Rotation at the end of onboarding (README §7).
@Suite("Starter Rotations in the store")
@MainActor
struct StarterRotationStoreTests {
    let container: ModelContainer
    var log: TrainingLog { TrainingLog(context: container.mainContext) }

    init() throws {
        container = try StoreContainer.make(inMemory: true)
        try ExerciseCatalog.seed(into: container.mainContext)
    }

    @Test func everyStarterExerciseIsInTheCatalogAndFitsTheEquipmentAccess() {
        let catalog = Dictionary(uniqueKeysWithValues: ExerciseCatalog.entries.map { ($0.key, $0) })
        for kind in StarterRotation.Kind.allCases {
            for access in EquipmentAccess.allCases {
                let rotation = StarterRotation.make(kind, for: access)
                for planned in rotation.workouts.flatMap(\.plannedExercises) {
                    let entry = catalog[planned.catalogKey]
                    #expect(entry != nil, "\(planned.catalogKey)")
                    #expect(entry.map { access.equipment.contains($0.equipment) } ?? false, "\(planned.catalogKey)")
                }
            }
        }
    }

    @Test func addingAStarterRotationAppendsItsWorkoutsWithTargetsRestAndSupersets() throws {
        let rotation = StarterRotation.make(.upperLower, for: .fullGym)

        let added = log.add(rotation, names: { $0 == .upperBody ? "Upper" : "Lower" }, weights: [:])

        #expect(log.workouts().map(\.name) == ["Upper", "Lower"])
        #expect(added.map(\.id) == log.workouts().map(\.id))
        let upper = try #require(added.first).orderedPlannedExercises
        #expect(upper.map { $0.exercise?.catalogKey } == rotation.workouts[0].plannedExercises.map(\.catalogKey))
        let bench = try #require(upper.first)
        #expect(bench.target == Target(sets: 3, reps: 10, weight: 0))
        #expect(bench.restSeconds == 90)
        #expect(bench.weightStep == Equipment.barbell.defaultWeightStep)
        // Seated Dumbbell Shoulder Press + Lat Pulldown, and Dumbbell Curl + Triceps Pushdown.
        #expect(upper[2].supersetID != nil && upper[2].supersetID == upper[3].supersetID)
        #expect(upper[5].supersetID != nil && upper[5].supersetID == upper[6].supersetID)
        #expect(upper[2].supersetID != upper[5].supersetID)
        #expect(upper[0].supersetID == nil && upper[4].supersetID == nil)
    }

    @Test func enteredWeightsBecomeTheTargetWeightAndTheRestStartAtZero() throws {
        let rotation = StarterRotation.make(.fullBody, for: .fullGym)

        let added = log.add(rotation, names: { _ in "Full Body" }, weights: ["back-squat": 60, "cable-curl": 12.5])

        let planned = try #require(added.first).orderedPlannedExercises
        #expect(planned.first { $0.exercise?.catalogKey == "back-squat" }?.weight == 60)
        #expect(planned.first { $0.exercise?.catalogKey == "cable-curl" }?.weight == 12.5)
        #expect(planned.first { $0.exercise?.catalogKey == "romanian-deadlift" }?.weight == 0)
    }

    @Test func theSameExerciseInTwoWorkoutsOfARotationIsLinkedWithOneTarget() throws {
        let squat = StarterRotation.PlannedExercise("back-squat", sets: 3, reps: 8, restSeconds: 120)
        let rotation = StarterRotation(
            kind: .upperLower, equipmentAccess: .fullGym,
            workouts: [
                .init(focus: .upperBody, plannedExercises: [squat]),
                .init(focus: .lowerBody, plannedExercises: [squat]),
            ])

        let added = log.add(rotation, names: { _ in "Day" }, weights: ["back-squat": 80])

        let first = try #require(added.first?.orderedPlannedExercises.first)
        let second = try #require(added.last?.orderedPlannedExercises.first)
        #expect(first.linkID != nil && first.linkID == second.linkID)
        #expect(second.target == Target(sets: 3, reps: 8, weight: 80))
        #expect(second.restSeconds == 120)
    }
}
