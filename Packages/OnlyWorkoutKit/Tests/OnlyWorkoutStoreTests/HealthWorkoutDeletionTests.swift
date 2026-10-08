import Foundation
import OnlyWorkoutCore
import SwiftData
import Testing

@testable import OnlyWorkoutStore

/// Deleting a Session also deletes its Apple Health workout, on the device that saved it (README §11).
@Suite("Health workout deletion")
@MainActor
struct HealthWorkoutDeletionTests {
    let phoneContainer: ModelContainer
    let watchContainer: ModelContainer
    var phone: TrainingLog { TrainingLog(context: phoneContainer.mainContext) }
    var watch: TrainingLog { TrainingLog(context: watchContainer.mainContext) }
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    init() throws {
        phoneContainer = try StoreContainer.make(inMemory: true)
        watchContainer = try StoreContainer.make(inMemory: true)
        try ExerciseCatalog.seed(into: phoneContainer.mainContext)
        try ExerciseCatalog.seed(into: watchContainer.mainContext)
    }

    /// A finished Session of a one-Set Workout, saved to Health as `healthWorkoutID`.
    func finishedSession(on log: TrainingLog, recordedOn device: Session.Device, healthWorkoutID: UUID = UUID())
        throws -> Session
    {
        let workout = try #require(log.workouts().first ?? log.addWorkout(named: "Leg Day", now: start))
        var (session, engine) = log.startSession(workout, recordedOn: device, now: start)
        engine.end()
        log.finish(session, engine: engine, now: start.addingTimeInterval(1_800))
        log.attachHealthWorkout(healthWorkoutID, to: session, now: start.addingTimeInterval(1_800))
        return session
    }

    @Test func aDeletedSessionOwesItsHealthWorkoutDeletionOnTheDeviceThatRecordedIt() throws {
        let session = try finishedSession(on: phone, recordedOn: .phone)

        phone.delete(session, now: start.addingTimeInterval(3_600))

        #expect(phone.healthWorkoutsToDelete(recordedOn: .phone) == [session])
        #expect(phone.healthWorkoutsToDelete(recordedOn: .watch).isEmpty)
    }

    @Test func aHealthWorkoutOnceDeletedIsNotOwedAgain() throws {
        let session = try finishedSession(on: phone, recordedOn: .phone)
        phone.delete(session, now: start.addingTimeInterval(3_600))

        phone.forgetHealthWorkout(of: session)

        #expect(phone.healthWorkoutsToDelete(recordedOn: .phone).isEmpty)
    }

    @Test func aSessionDeletedOnAnotherDeviceOwesTheDeletionOnceItsTombstoneArrives() throws {
        let session = try finishedSession(on: phone, recordedOn: .phone)
        let cloudContainer = try StoreContainer.make(inMemory: true)
        let cloud = TrainingLog(context: cloudContainer.mainContext)
        cloud.apply(phone.exportSessions([session]), fromCloud: true)
        let elsewhere = try #require(cloud.fetchAll(Session.self).first)
        elsewhere.healthWorkoutID = nil  // never leaves the device that saved it
        cloud.delete(elsewhere, now: start.addingTimeInterval(3_600))

        phone.apply(cloud.exportSessions([elsewhere]), fromCloud: true)

        #expect(phone.healthWorkoutsToDelete(recordedOn: .phone) == [session])
    }

    @Test func theWatchSnapshotCarriesADeletedWatchSessionSoTheWatchDeletesItsHealthWorkout() throws {
        _ = phone.addWorkout(named: "Leg Day", now: start)
        watch.apply(phone.watchSnapshot())
        let recorded = try finishedSession(on: watch, recordedOn: .watch)
        phone.apply(watch.exportSessions([recorded]))
        let onPhone = try #require(phone.fetchAll(Session.self).first)

        phone.delete(onPhone, now: start.addingTimeInterval(3_600))
        watch.apply(phone.watchSnapshot(now: start.addingTimeInterval(7_200)))

        #expect(phone.healthWorkoutsToDelete(recordedOn: .phone).isEmpty)
        #expect(watch.healthWorkoutsToDelete(recordedOn: .watch) == [recorded])
    }

    @Test func aWatchSessionDeletedLongAgoIsLeftOutOfTheWatchSnapshot() throws {
        let session = try finishedSession(on: phone, recordedOn: .watch)
        phone.delete(session, now: start.addingTimeInterval(3_600))

        let snapshot = phone.watchSnapshot(now: start.addingTimeInterval(31 * 86_400))

        #expect(snapshot.sessions.isEmpty)
    }

    @Test func theWatchDoesNotOweADeletedHealthWorkoutAgainWhenTheSameSnapshotArrives() throws {
        _ = phone.addWorkout(named: "Leg Day", now: start)
        watch.apply(phone.watchSnapshot())
        let recorded = try finishedSession(on: watch, recordedOn: .watch)
        phone.apply(watch.exportSessions([recorded]))
        phone.delete(try #require(phone.fetchAll(Session.self).first), now: start.addingTimeInterval(3_600))
        let snapshot = phone.watchSnapshot(now: start.addingTimeInterval(7_200))
        watch.apply(snapshot)

        watch.forgetHealthWorkout(of: recorded)
        watch.apply(snapshot)

        #expect(watch.healthWorkoutsToDelete(recordedOn: .watch).isEmpty)
    }
}
