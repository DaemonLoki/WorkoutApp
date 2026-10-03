import Foundation
import OnlyWorkoutCore
import SwiftData
import Testing

@testable import OnlyWorkoutStore

/// Which records the iPhone still owes the cloud, and what a pull does to them (README §10).
@Suite("Cloud bookkeeping")
@MainActor
struct CloudBookkeepingTests {
    let container: ModelContainer
    var log: TrainingLog { TrainingLog(context: container.mainContext) }

    init() throws {
        container = try StoreContainer.make(inMemory: true)
        try ExerciseCatalog.seed(into: container.mainContext)
    }

    func catalogExercise(_ key: String) throws -> Exercise {
        try #require(
            try log.context.fetch(FetchDescriptor<Exercise>(predicate: #Predicate { $0.catalogKey == key })).first)
    }

    @Test func aCatalogExerciseEditedInTheCloudSurvivesAFreshInstall() throws {
        let squat = try catalogExercise("back-squat")
        var edited = ExerciseRecord(squat)
        edited.name = "High-Bar Squat"
        edited.updatedAt = Date(timeIntervalSince1970: 1_700_000_000)

        var batch = RecordBatch()
        batch.exercises = [edited]
        log.apply(batch, fromCloud: true)

        #expect(try catalogExercise("back-squat").name == "High-Bar Squat")
    }

    @Test func aNewWorkoutIsOwedToTheCloudUntilItIsPushed() throws {
        let workout = log.addWorkout(named: "Leg Day")

        let pending = log.pendingPush()
        #expect(pending.workouts.map(\.id) == [workout.id])

        log.markPushed(pending)
        #expect(log.pendingPush().workouts.isEmpty)
    }

    @Test func recordsPulledFromTheCloudAreNotPushedBack() throws {
        let otherContainer = try StoreContainer.make(inMemory: true)
        let otherPhone = TrainingLog(context: otherContainer.mainContext)
        otherPhone.addWorkout(named: "Pull Day")

        log.apply(otherPhone.exportPlan(), fromCloud: true)

        #expect(log.workouts().map(\.name) == ["Pull Day"])
        #expect(log.pendingPush().workouts.isEmpty)
    }

    @Test func aWatchSessionArrivingAfterAPushIsStillOwedToTheCloud() throws {
        let workout = log.addWorkout(named: "Leg Day")
        log.add(try catalogExercise("back-squat"), to: workout)
        let watchContainer = try StoreContainer.make(inMemory: true)
        try ExerciseCatalog.seed(into: watchContainer.mainContext)
        let watch = TrainingLog(context: watchContainer.mainContext)
        watch.apply(log.watchSnapshot())
        var (session, engine) = watch.startSession(try #require(watch.workouts().first), recordedOn: .watch)
        engine.completeSet(reps: 10, weight: 20, at: .now)
        watch.finish(session, engine: engine)

        log.markPushed(log.pendingPush())
        log.apply(watch.exportSessions([session]))

        let pending = log.pendingPush()
        #expect(pending.sessions.map(\.id) == [session.id])
        #expect(pending.sets.count == 1)
    }

    @Test func afterSigningOutEverythingIsOwedToTheNextAccount() throws {
        let workout = log.addWorkout(named: "Leg Day")
        log.markPushed(log.pendingPush())

        log.forgetSyncedVersions()

        #expect(log.pendingPush().workouts.map(\.id) == [workout.id])
    }
}
