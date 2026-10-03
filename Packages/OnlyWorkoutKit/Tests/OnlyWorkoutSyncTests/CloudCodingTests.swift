import Foundation
import OnlyWorkoutCore
import OnlyWorkoutStore
import SwiftData
import Testing

@testable import OnlyWorkoutSync

/// The JSON exchanged with `sync_push` / `sync_pull` (supabase/migrations).
@Suite("Cloud coding")
@MainActor
struct CloudCodingTests {
    let container: ModelContainer
    var log: TrainingLog { TrainingLog(context: container.mainContext) }

    init() throws {
        container = try StoreContainer.make(inMemory: true)
    }

    func pushedJSON() throws -> [String: Any] {
        let data = try CloudCoding.encodePush(log.pendingPush())
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test func aPushIsKeyedByTableAndColumnNames() throws {
        let workout = log.addWorkout(named: "Leg Day")
        let (session, _) = log.startSession(workout, recordedOn: .phone)
        session.healthWorkoutID = UUID()

        let json = try pushedJSON()
        let sessions = try #require(json["sessions"] as? [[String: Any]])
        let row = try #require(sessions.first)

        #expect(row["workout_name"] as? String == "Leg Day")
        #expect(row["recorded_on"] as? String == "phone")
        #expect(row["workout_id"] as? String == workout.id.uuidString)
        #expect(row["started_at"] is String)
        #expect(row["health_workout_id"] == nil)
        #expect(row["healthWorkoutID"] == nil)
    }

    @Test func aPushedDateIsUTCWithMilliseconds() throws {
        // 2026-09-05 18:05:00.123 UTC
        log.addWorkout(named: "Leg Day", now: Date(timeIntervalSince1970: 1_788_631_500.123))

        let workouts = try #require(try pushedJSON()["workouts"] as? [[String: Any]])

        #expect(workouts.first?["updated_at"] as? String == "2026-09-05T18:05:00.123Z")
    }

    /// Captured from `sync_pull` on the local stack: Postgres drops trailing zeros from fractions.
    static let pulled = Data(
        """
        {
          "sets": [{"id": "60000000-0000-0000-0000-000000000001", "reps": 8, "number": 1, "weight": 82.5,
            "is_extra": false, "created_at": "2026-09-05T18:05:00.123+00:00", "deleted_at": null,
            "updated_at": "2026-09-05T18:05:00.123+00:00", "completed_at": "2026-09-05T18:05:00.123+00:00",
            "session_exercise_id": "50000000-0000-0000-0000-000000000001"}],
          "cursor": "2026-09-30T18:42:46.760643+00:00",
          "sessions": [{"id": "40000000-0000-0000-0000-000000000001", "ended_at": "2026-09-05T19:00:00.25+00:00",
            "created_at": "2026-09-05T18:00:00+00:00", "deleted_at": null, "started_at": "2026-09-05T18:00:00+00:00",
            "updated_at": "2026-09-05T19:00:00.25+00:00", "workout_id": "10000000-0000-0000-0000-000000000001",
            "recorded_on": "watch", "workout_name": "Leg Day", "strava_activity_id": null}],
          "workouts": [],
          "exercises": [{"id": "20000000-0000-0000-0000-000000000001", "name": "Back Squat", "equipment": "barbell",
            "created_at": "1970-01-01T00:00:00+00:00", "deleted_at": null, "updated_at": "1970-01-01T00:00:00+00:00",
            "archived_at": null, "catalog_key": "back-squat", "muscle_groups": ["quads", "glutes"],
            "strava_exercise_type": null}],
          "planned_exercises": [],
          "session_exercises": [],
          "progression_suggestions": []
        }
        """.utf8)

    @Test func aPullBecomesRecordsAndACursor() throws {
        let (batch, cursor) = try CloudCoding.decodePull(Self.pulled)

        let set = try #require(batch.sets.first)
        #expect(set.sessionExerciseID == UUID(uuidString: "50000000-0000-0000-0000-000000000001"))
        #expect(set.reps == 8)
        #expect(set.weight == 82.5)
        #expect(abs(set.updatedAt.timeIntervalSince1970 - 1_788_631_500.123) < 0.000_5)

        let session = try #require(batch.sessions.first)
        #expect(session.workoutName == "Leg Day")
        #expect(session.healthWorkoutID == nil)
        #expect(abs(try #require(session.endedAt).timeIntervalSince1970 - 1_788_634_800.25) < 0.000_5)

        #expect(batch.exercises.first?.catalogKey == "back-squat")
        #expect(batch.exercises.first?.updatedAt == Date(timeIntervalSince1970: 0))
        #expect(abs(try #require(cursor).timeIntervalSince1970 - 1_790_793_766.760_643) < 0.000_001)
    }
}
