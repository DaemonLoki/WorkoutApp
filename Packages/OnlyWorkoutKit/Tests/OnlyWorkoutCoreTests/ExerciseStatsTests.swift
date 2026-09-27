import Foundation
import Testing

@testable import OnlyWorkoutCore

@Suite("ExerciseStats")
struct ExerciseStatsTests {
    let day: TimeInterval = 86_400
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func result(daysAgo: Double, target: Double, sets: [(Int, Double)], planned: UUID? = nil) -> ExerciseResult {
        ExerciseResult(
            date: now.addingTimeInterval(-daysAgo * day),
            target: Target(sets: sets.count, reps: 10, weight: target),
            sets: sets.map { LoggedSet(reps: $0.0, weight: $0.1) },
            plannedExerciseID: planned
        )
    }

    @Test func eachSessionWithSetsIsOnePointAtItsHeaviestSetOldestFirst() {
        let stats = ExerciseStats(results: [
            result(daysAgo: 2, target: 60, sets: [(10, 60), (8, 62.5)]),
            result(daysAgo: 9, target: 57.5, sets: [(10, 57.5)]),
            result(daysAgo: 5, target: 60, sets: []),
        ])

        #expect(stats.points.map(\.workingWeight) == [57.5, 62.5])
        #expect(stats.points.map(\.date) == [now.addingTimeInterval(-9 * day), now.addingTimeInterval(-2 * day)])
    }

    @Test func aStepUpIsMarkedWhenTheTargetWeightRoseSinceTheSamePlannedExercisesPreviousSession() {
        let legDayA = UUID()
        let legDayB = UUID()
        let stats = ExerciseStats(results: [
            result(daysAgo: 10, target: 40, sets: [(12, 40)], planned: legDayA),
            result(daysAgo: 8, target: 80, sets: [(5, 80)], planned: legDayB),
            result(daysAgo: 6, target: 42.5, sets: [(10, 42.5)], planned: legDayA),
            result(daysAgo: 4, target: 80, sets: [(5, 80)], planned: legDayB),
        ])

        #expect(stats.points.map(\.isStepUp) == [false, false, true, false])
    }

    @Test func bestSetIsTheHeaviestThenTheMostRepsAndTotalsCoverEverySet() {
        let stats = ExerciseStats(results: [
            result(daysAgo: 3, target: 60, sets: [(10, 60), (7, 62.5)]),
            result(daysAgo: 1, target: 62.5, sets: [(9, 62.5), (12, 50)]),
        ])

        #expect(stats.bestSet == LoggedSet(reps: 9, weight: 62.5))
        #expect(stats.totalVolume == 600 + 437.5 + 562.5 + 600)
        #expect(stats.totalReps == 38)
    }

    @Test func weightChangeIsLatestMinusEarliestWorkingWeight() {
        let stats = ExerciseStats(results: [
            result(daysAgo: 30, target: 60, sets: [(10, 60)]),
            result(daysAgo: 1, target: 67.5, sets: [(8, 67.5)]),
        ])

        #expect(stats.weightChange == 7.5)
        #expect(ExerciseStats(results: []).weightChange == nil)
    }

    @Test func aTimeRangeKeepsOnlyDatesInsideIt() {
        let calendar = Calendar(identifier: .gregorian)
        let range = StatsRange.fourWeeks

        #expect(range.contains(now.addingTimeInterval(-27 * day), now: now, calendar: calendar))
        #expect(!range.contains(now.addingTimeInterval(-29 * day), now: now, calendar: calendar))
        #expect(StatsRange.all.contains(.distantPast, now: now, calendar: calendar))
    }
}
