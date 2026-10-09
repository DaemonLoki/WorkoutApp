import Testing

@testable import OnlyWorkoutCore

@Suite("StarterRotation")
struct StarterRotationTests {
    static let all = StarterRotation.Kind.allCases.flatMap { kind in
        EquipmentAccess.allCases.map { StarterRotation.make(kind, for: $0) }
    }

    @Test func eachStarterRotationHasItsWorkoutsInRotationOrder() {
        for access in EquipmentAccess.allCases {
            #expect(StarterRotation.make(.fullBody, for: access).workouts.map(\.focus) == [.fullBody])
            #expect(StarterRotation.make(.upperLower, for: access).workouts.map(\.focus) == [.upperBody, .lowerBody])
            #expect(StarterRotation.make(.pushPullLegs, for: access).workouts.map(\.focus) == [.push, .pull, .legs])
        }
    }

    @Test func everyWorkoutHasFourToSevenExercises() {
        for rotation in Self.all {
            for workout in rotation.workouts {
                #expect((4...7).contains(workout.plannedExercises.count), "\(rotation.kind) \(workout.focus)")
            }
        }
    }

    @Test func everyTargetAndRestIsOneTheEditorCanShow() {
        for planned in Self.all.flatMap(\.workouts).flatMap(\.plannedExercises) {
            #expect(PlanDefaults.setsRange.contains(planned.sets), "\(planned.catalogKey)")
            #expect(PlanDefaults.repsRange.contains(planned.reps), "\(planned.catalogKey)")
            #expect(PlanDefaults.restRange.contains(planned.restSeconds), "\(planned.catalogKey)")
            #expect(planned.restSeconds % PlanDefaults.restStep == 0, "\(planned.catalogKey)")
        }
    }

    @Test func aSupersetPairsTwoNeighboursAndNeverThree() {
        for workout in Self.all.flatMap(\.workouts) {
            let flags = workout.plannedExercises.map(\.supersetsWithNext)
            #expect(flags.last != true, "\(workout.focus)")
            #expect(!zip(flags, flags.dropFirst()).contains { $0 && $1 }, "\(workout.focus)")
        }
    }

    @Test func noExerciseIsPlannedTwiceInOneWorkout() {
        for workout in Self.all.flatMap(\.workouts) {
            let keys = workout.plannedExercises.map(\.catalogKey)
            #expect(Set(keys).count == keys.count, "\(workout.focus)")
        }
    }

    /// The same Exercise in two Workouts of a Rotation is linked when added, so it needs one Target (ADR-0006).
    @Test func theSameExerciseHasOneTargetAcrossARotation() {
        for rotation in Self.all {
            let byKey = Dictionary(grouping: rotation.workouts.flatMap(\.plannedExercises), by: \.catalogKey)
            for (key, planned) in byKey {
                #expect(Set(planned.map { [$0.sets, $0.reps, $0.restSeconds] }).count == 1, "\(key)")
            }
        }
    }
}
