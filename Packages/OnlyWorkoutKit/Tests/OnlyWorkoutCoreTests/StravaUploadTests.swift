import Foundation
import Testing

@testable import OnlyWorkoutCore

@Suite("StravaUpload")
struct StravaUploadTests {
    let start = Date(timeIntervalSince1970: 1_790_000_000)  // 2026-09-21T14:13:20Z

    func set(_ type: String?, reps: Int, weight: Double, after minutes: Double) -> StravaUpload.PerformedSet {
        StravaUpload.PerformedSet(
            exerciseType: type, set: LoggedSet(reps: reps, weight: weight),
            completedAt: start.addingTimeInterval(minutes * 60))
    }

    /// Both sides as JSON objects, so key order and number formatting don't matter.
    func json(_ data: Data) throws -> NSDictionary {
        try #require(try JSONSerialization.jsonObject(with: data) as? NSDictionary)
    }

    /// Strava lists Sets as they come, so a Superset sent in performed order shows interleaved; the owner
    /// wants each Exercise's Sets together, Exercises in the order they were started.
    @Test func aSessionBecomesStravasStrengthFileWithEachExercisesSetsTogether() throws {
        let upload = try #require(
            StravaUpload(
                startedAt: start, endedAt: start.addingTimeInterval(3_600), utcOffset: 7_200, creator: "OnlyWorkout",
                sets: [
                    // A Superset: bench, row, bench, row, handed over in no particular order.
                    set("SEATED_CABLE_ROW", reps: 9, weight: 45.5, after: 14),
                    set("BARBELL_BENCH_PRESS", reps: 7, weight: 60, after: 11),
                    set("SEATED_CABLE_ROW", reps: 10, weight: 45.5, after: 8),
                    set("BARBELL_BENCH_PRESS", reps: 8, weight: 60, after: 5),
                ]))

        let expected = Data(
            """
            {"version": "1.0", "start_time": "2026-09-21T14:13:20Z", "utc_offset": 7200, "elapsed_time": 3600,
             "creator": {"name": "OnlyWorkout"},
             "sets": [{"exercise_type": "BARBELL_BENCH_PRESS", "repetitions": 8, "weight": 60},
                      {"exercise_type": "BARBELL_BENCH_PRESS", "repetitions": 7, "weight": 60},
                      {"exercise_type": "SEATED_CABLE_ROW", "repetitions": 10, "weight": 45.5},
                      {"exercise_type": "SEATED_CABLE_ROW", "repetitions": 9, "weight": 45.5}]}
            """.utf8)
        #expect(try json(upload.file()) == json(expected))
    }

    @Test func aBodyweightSetWithoutAddedWeightIsSentWithoutWeight() throws {
        let upload = try #require(
            StravaUpload(
                startedAt: start, endedAt: start.addingTimeInterval(600), utcOffset: 0, creator: "OnlyWorkout",
                sets: [set("PULL_UP_GENERIC", reps: 6, weight: 0, after: 2)]))

        let sets = try #require(try json(upload.file())["sets"] as? [NSDictionary])
        #expect(sets == [["exercise_type": "PULL_UP_GENERIC", "repetitions": 6]])
    }

    @Test func setsOfAnExerciseWithoutAStravaTypeAreLeftOut() throws {
        let upload = try #require(
            StravaUpload(
                startedAt: start, endedAt: start.addingTimeInterval(600), utcOffset: 0, creator: "OnlyWorkout",
                sets: [set(nil, reps: 12, weight: 20, after: 1), set("DUMBBELL_SHRUG", reps: 12, weight: 24, after: 3)])
        )

        let sets = try #require(try json(upload.file())["sets"] as? [NSDictionary])
        #expect(sets == [["exercise_type": "DUMBBELL_SHRUG", "repetitions": 12, "weight": 24]])
    }

    /// A type Strava doesn't know would fail the whole upload.
    @Test func setsWithATypeStravaDoesNotKnowAreLeftOut() throws {
        let upload = try #require(
            StravaUpload(
                startedAt: start, endedAt: start.addingTimeInterval(600), utcOffset: 0, creator: "OnlyWorkout",
                sets: [
                    set("BICEPS_CURL", reps: 10, weight: 12, after: 1),
                    set("CURL_GENERIC", reps: 10, weight: 12, after: 3),
                ]))

        let sets = try #require(try json(upload.file())["sets"] as? [NSDictionary])
        #expect(sets == [["exercise_type": "CURL_GENERIC", "repetitions": 10, "weight": 12]])
    }

    /// Strava needs at least one Set, e.g. not for a Session of Custom Exercises without a Strava type.
    @Test func aSessionWithNoSetToSendHasNoUpload() {
        let upload = StravaUpload(
            startedAt: start, endedAt: start.addingTimeInterval(600), utcOffset: 0, creator: "OnlyWorkout",
            sets: [set(nil, reps: 12, weight: 20, after: 1)])

        #expect(upload == nil)
    }
}
