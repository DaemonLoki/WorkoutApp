import Foundation
import Testing

@testable import OnlyWorkoutCore

@Suite("Progression")
struct ProgressionTests {
    let target = Target(sets: 3, reps: 12, weight: 40)

    @Test func targetHitWhenEveryPlannedSetReachesTargetRepsAtTargetWeight() {
        let result = ExerciseResult(
            date: .now,
            target: target,
            sets: [.init(reps: 12, weight: 40), .init(reps: 12, weight: 40), .init(reps: 12, weight: 40)]
        )

        #expect(Progression.isTargetHit(result))
    }

    @Test func notATargetHitWhenFewerPlannedSetsThanTargetWereLogged() {
        let result = ExerciseResult(
            date: .now,
            target: target,
            sets: [.init(reps: 12, weight: 40), .init(reps: 12, weight: 40)]
        )

        #expect(!Progression.isTargetHit(result))
    }

    @Test func extraSetsNeitherCountTowardsNorAgainstATargetHit() {
        let hitWithWeakExtra = ExerciseResult(
            date: .now,
            target: target,
            sets: [
                .init(reps: 13, weight: 40), .init(reps: 12, weight: 40), .init(reps: 12, weight: 40),
                .init(reps: 6, weight: 40, isExtra: true),
            ]
        )
        let missPaddedWithExtras = ExerciseResult(
            date: .now,
            target: target,
            sets: [
                .init(reps: 12, weight: 40), .init(reps: 12, weight: 40),
                .init(reps: 12, weight: 40, isExtra: true),
            ]
        )

        #expect(Progression.isTargetHit(hitWithWeakExtra))
        #expect(!Progression.isTargetHit(missPaddedWithExtras))
    }

    @Test func aMissedRepOrAChangedWeightIsNotATargetHit() {
        let missedRep = ExerciseResult(
            date: .now,
            target: target,
            sets: [.init(reps: 12, weight: 40), .init(reps: 12, weight: 40), .init(reps: 11, weight: 40)]
        )
        let changedWeight = ExerciseResult(
            date: .now,
            target: target,
            sets: [.init(reps: 12, weight: 40), .init(reps: 12, weight: 42.5), .init(reps: 12, weight: 40)]
        )

        #expect(!Progression.isTargetHit(missedRep))
        #expect(!Progression.isTargetHit(changedWeight))
    }

    @Test func aTargetHitOffersAStepUpByOneWeightStepOrByOneRep() {
        let hit = session([12, 12, 12])

        let suggestion = Progression.suggestion(history: [hit], current: at(40), weightStep: 2.5)

        #expect(
            suggestion
                == WeightSuggestion(
                    kind: .stepUp, reason: .targetHit, fromWeight: 40, toWeight: 42.5, fromReps: 12, toReps: 13))
        #expect(suggestion?.changes == [.weight, .reps])
    }

    /// The Planned Exercise's Target now: 3 × `reps` @ `weight`.
    func at(_ weight: Double, reps: Int = 12) -> Target {
        Target(sets: 3, reps: reps, weight: weight)
    }

    /// A Session at `weight` whose planned Sets had the given reps (Target stays 3×12 @ `weight`).
    func session(_ reps: [Int], weight: Double = 40) -> ExerciseResult {
        ExerciseResult(
            date: .now,
            target: Target(sets: 3, reps: 12, weight: weight),
            sets: reps.map { LoggedSet(reps: $0, weight: weight) }
        )
    }

    @Test func threeMissesWithoutANewBestTotalAreAStallAndSuggestAStepDown() {
        // Totals 30, 28, 29 — README §4 example.
        let history = [session([10, 10, 10]), session([10, 10, 8]), session([10, 10, 9])]

        let suggestion = Progression.suggestion(history: history, current: at(40), weightStep: 2.5)

        #expect(
            suggestion
                == WeightSuggestion(
                    kind: .stepDown, reason: .stall, fromWeight: 40, toWeight: 37.5, fromReps: 12, toReps: 12))
    }

    @Test(arguments: [
        [[10, 10, 8], [10, 10, 10], [10, 10, 10]],  // 28, 30, 30: second Session improved
        [[10, 10, 10], [11, 10, 10], [11, 11, 11]],  // 30, 31, 33: still progressing
    ])
    func missesThatStillSetANewBestTotalAreNotAStall(reps: [[Int]]) {
        let history = reps.map { session($0) }

        #expect(Progression.suggestion(history: history, current: at(40), weightStep: 2.5) == nil)
    }

    @Test func missesRightAfterAStepUpOnlyCountAtTheNewWeight() {
        let history = [session([10, 10, 10], weight: 37.5), session([10, 10, 8]), session([10, 10, 9])]

        #expect(Progression.suggestion(history: history, current: at(40), weightStep: 2.5) == nil)
    }

    @Test func aStepDownNeverGoesBelowZero() {
        let history = [session([5, 5, 5], weight: 2), session([5, 5, 4], weight: 2), session([5, 4, 4], weight: 2)]

        let suggestion = Progression.suggestion(history: history, current: at(2), weightStep: 2.5)

        #expect(suggestion?.toWeight == 0)
    }

    @Test func aStallAtZeroKilogramsStepsDownOneRep() {
        let history = [session([5, 5, 5], weight: 0), session([5, 5, 4], weight: 0), session([5, 4, 4], weight: 0)]

        let suggestion = Progression.suggestion(history: history, current: at(0), weightStep: 2.5)

        #expect(
            suggestion
                == WeightSuggestion(
                    kind: .stepDown, reason: .stall, fromWeight: 0, toWeight: 0, fromReps: 12, toReps: 11))
    }

    @Test func aStepDownNeverGoesBelowOneRep() {
        let history = [session([0, 0, 0], weight: 0), session([0, 0, 0], weight: 0), session([0, 0, 0], weight: 0)]

        #expect(Progression.suggestion(history: history, current: at(0, reps: 1), weightStep: 2.5) == nil)
    }

    @Test func moreThanTwentyOneDaysAwayIsALayoffAndSuggestsAStepDown() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let day: TimeInterval = 86_400

        let afterLayoff = Progression.layoffSuggestion(
            lastPerformed: now.addingTimeInterval(-22 * day), now: now, current: at(60), weightStep: 2.5)
        let afterThreeWeeks = Progression.layoffSuggestion(
            lastPerformed: now.addingTimeInterval(-21 * day), now: now, current: at(60), weightStep: 2.5)
        let neverPerformed = Progression.layoffSuggestion(
            lastPerformed: nil, now: now, current: at(60), weightStep: 2.5)

        #expect(
            afterLayoff
                == WeightSuggestion(
                    kind: .stepDown, reason: .layoff, fromWeight: 60, toWeight: 57.5, fromReps: 12, toReps: 12))
        #expect(afterThreeWeeks == nil)
        #expect(neverPerformed == nil)
    }

    @Test func aSessionWithASkippedSetIsNeitherATargetHitNorCountedTowardsAStall() {
        var skippedOne = session([12, 12])
        skippedOne.skippedSets = 1
        let history = [session([10, 10, 10]), skippedOne, session([10, 10, 9])]

        #expect(!Progression.isTargetHit(skippedOne))
        #expect(Progression.suggestion(history: history, current: at(40), weightStep: 2.5) == nil)
    }

    @Test func choosingOneChangeOfAStepUpLeavesTheOtherOneOut() {
        let stepUp = WeightSuggestion(
            kind: .stepUp, reason: .targetHit, fromWeight: 40, toWeight: 42.5, fromReps: 12, toReps: 13)

        #expect(
            stepUp.choosing(.reps)
                == WeightSuggestion(
                    kind: .stepUp, reason: .targetHit, fromWeight: 40, toWeight: 40, fromReps: 12, toReps: 13))
        #expect(
            stepUp.choosing(.weight)
                == WeightSuggestion(
                    kind: .stepUp, reason: .targetHit, fromWeight: 40, toWeight: 42.5, fromReps: 12, toReps: 12))
    }

    @Test func missesRightAfterARepStepUpOnlyCountAtTheNewReps() {
        let beforeStepUp = ExerciseResult(
            date: .now, target: Target(sets: 3, reps: 11, weight: 40),
            sets: [.init(reps: 10, weight: 40), .init(reps: 10, weight: 40), .init(reps: 10, weight: 40)])
        let history = [beforeStepUp, session([10, 10, 8]), session([10, 10, 9])]

        #expect(Progression.suggestion(history: history, current: at(40), weightStep: 2.5) == nil)
    }

    @Test func aLayoffAtZeroKilogramsStepsDownOneRep() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let suggestion = Progression.layoffSuggestion(
            lastPerformed: now.addingTimeInterval(-30 * 86_400), now: now, current: at(0, reps: 8), weightStep: 2.5)

        #expect(
            suggestion
                == WeightSuggestion(
                    kind: .stepDown, reason: .layoff, fromWeight: 0, toWeight: 0, fromReps: 8, toReps: 7))
    }
}
