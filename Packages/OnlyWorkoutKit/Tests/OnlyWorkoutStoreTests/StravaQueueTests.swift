import Foundation
import OnlyWorkoutCore
import SwiftData
import Testing

@testable import OnlyWorkoutStore

/// Which Sessions still go to Strava, what they carry, and how long the activity ID stays (README §12).
@Suite("Strava queue")
@MainActor
struct StravaQueueTests {
    let container: ModelContainer
    var log: TrainingLog { TrainingLog(context: container.mainContext) }
    let workout: Workout
    let connectedAt = Date(timeIntervalSince1970: 1_790_000_000)
    let berlin = TimeZone(identifier: "Europe/Berlin")!

    init() throws {
        container = try StoreContainer.make(inMemory: true)
        try ExerciseCatalog.seed(into: container.mainContext)
        let log = TrainingLog(context: container.mainContext)
        let key = "back-squat"
        let squat = try #require(
            try log.context.fetch(FetchDescriptor<Exercise>(predicate: #Predicate { $0.catalogKey == key })).first)
        workout = log.addWorkout(named: "Leg Day")
        let planned = log.add(squat, to: workout)
        planned.targetSets = 2
        planned.targetReps = 5
        planned.weight = 80
    }

    /// A Session of two Squat Sets, `hours` after connecting.
    @discardableResult
    func finishedSession(hoursAfterConnecting hours: Double) -> Session {
        let start = connectedAt.addingTimeInterval(hours * 3_600)
        let (session, engine) = log.startSession(workout, now: start)
        let runner = SessionRunner(session: session, engine: engine, log: log, now: { start.addingTimeInterval(600) })
        runner.completeSet(reps: 5, weight: 80)
        runner.completeSet(reps: 5, weight: 80)
        runner.finish()
        return session
    }

    @Test func onlySessionsFinishedAfterConnectingAwaitUpload() throws {
        finishedSession(hoursAfterConnecting: -24)
        let session = finishedSession(hoursAfterConnecting: 2)

        let queued = log.sessionsAwaitingStravaUpload(finishedSince: connectedAt)
        #expect(queued.map(\.id) == [session.id])

        let upload = try #require(log.stravaUpload(of: session, creator: "OnlyWorkout", timeZone: berlin))
        #expect(upload.utcOffset == 7_200)  // summer time in Berlin
        #expect(upload.sets.map(\.exerciseType) == ["BARBELL_BACK_SQUAT", "BARBELL_BACK_SQUAT"])
        #expect(upload.sets.map(\.set) == [LoggedSet(reps: 5, weight: 80), LoggedSet(reps: 5, weight: 80)])
    }

    @Test func anUploadedSessionLeavesTheQueueAndIsOwedToTheCloud() throws {
        let session = finishedSession(hoursAfterConnecting: 2)
        log.markPushed(log.pendingPush())

        log.markUploadedToStrava(session, activityID: 16_000_000_001, now: connectedAt.addingTimeInterval(3 * 3_600))

        #expect(log.sessionsAwaitingStravaUpload(finishedSince: connectedAt).isEmpty)
        #expect(session.stravaActivityID == 16_000_000_001)
        #expect(log.pendingPush().sessions.map(\.id) == [session.id])
    }

    @Test func theUploadMarkTravelsButTheActivityIDStaysOnThisIPhone() throws {
        let session = finishedSession(hoursAfterConnecting: 2)
        log.markUploadedToStrava(session, activityID: 16_000_000_001, now: connectedAt.addingTimeInterval(3 * 3_600))

        let otherContainer = try StoreContainer.make(inMemory: true)
        let reinstalled = TrainingLog(context: otherContainer.mainContext)
        reinstalled.apply(log.pendingPush(), fromCloud: true)

        let restored = try #require(reinstalled.lastStartedSession())
        #expect(restored.stravaUploadedAt == connectedAt.addingTimeInterval(3 * 3_600))
        #expect(restored.stravaActivityID == nil)
        #expect(reinstalled.sessionsAwaitingStravaUpload(finishedSince: connectedAt).isEmpty)
    }

    /// Strava API Policy §6.2: no Strava Data in a cache for longer than 7 days.
    @Test func theActivityIDIsForgottenSevenDaysAfterTheUploadButTheMarkStays() throws {
        let session = finishedSession(hoursAfterConnecting: 2)
        let uploadedAt = connectedAt.addingTimeInterval(3 * 3_600)
        log.markUploadedToStrava(session, activityID: 16_000_000_001, now: uploadedAt)

        log.forgetExpiredStravaActivityIDs(now: uploadedAt.addingTimeInterval(7 * 86_400 - 60))
        #expect(session.stravaActivityID == 16_000_000_001)

        log.forgetExpiredStravaActivityIDs(now: uploadedAt.addingTimeInterval(7 * 86_400))
        #expect(session.stravaActivityID == nil)
        #expect(session.stravaUploadedAt == uploadedAt)
    }
}
