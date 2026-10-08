import Foundation
import OnlyWorkoutCore
import SwiftData
import Testing

@testable import OnlyWorkoutStore

/// Watch ↔ iPhone transfer: records exported from one store and applied to another (README §8, §10).
@Suite("Record transfer")
@MainActor
struct RecordTransferTests {
    let phoneContainer: ModelContainer
    let watchContainer: ModelContainer
    var phone: TrainingLog { TrainingLog(context: phoneContainer.mainContext) }
    var watch: TrainingLog { TrainingLog(context: watchContainer.mainContext) }

    init() throws {
        phoneContainer = try StoreContainer.make(inMemory: true)
        watchContainer = try StoreContainer.make(inMemory: true)
        try ExerciseCatalog.seed(into: phoneContainer.mainContext)
        try ExerciseCatalog.seed(into: watchContainer.mainContext)
    }

    func squat(in log: TrainingLog) throws -> Exercise {
        let key = "back-squat"
        return try #require(
            try log.context.fetch(FetchDescriptor<Exercise>(predicate: #Predicate { $0.catalogKey == key })).first)
    }

    @Test func aWorkoutAndItsPlannedExercisesArriveUnchanged() throws {
        let workout = phone.addWorkout(named: "Leg Day")
        workout.usesRestTimer = false
        let planned = phone.add(try squat(in: phone), to: workout)
        planned.targetReps = 5
        planned.weight = 80

        watch.apply(phone.exportPlan())

        let received = try #require(watch.workouts().first)
        #expect(received.id == workout.id)
        #expect(received.name == "Leg Day")
        #expect(!received.usesRestTimer)
        let receivedPlanned = try #require(received.orderedPlannedExercises.first)
        #expect(receivedPlanned.id == planned.id)
        #expect(receivedPlanned.target == Target(sets: 3, reps: 5, weight: 80))
        #expect(receivedPlanned.exercise?.catalogKey == "back-squat")
    }

    @Test func theNewerEditWinsAndAnOlderOneIsIgnored() throws {
        let workout = phone.addWorkout(named: "Leg Day", now: Date(timeIntervalSince1970: 1_000))
        watch.apply(phone.exportPlan())
        let onWatch = try #require(watch.workouts().first)
        onWatch.name = "Legs (watch)"
        onWatch.updatedAt = Date(timeIntervalSince1970: 2_000)

        watch.apply(phone.exportPlan())
        #expect(onWatch.name == "Legs (watch)")

        workout.name = "Legs (phone)"
        workout.updatedAt = Date(timeIntervalSince1970: 3_000)
        watch.apply(phone.exportPlan())
        #expect(onWatch.name == "Legs (phone)")
    }

    @Test func aDeletionCarriesOverAsATombstone() throws {
        let workout = phone.addWorkout(named: "Leg Day")
        watch.apply(phone.exportPlan())

        phone.delete(workout, now: .now.addingTimeInterval(60))
        watch.apply(phone.exportPlan())

        #expect(watch.workouts().isEmpty)
        #expect(watch.fetchAll(Workout.self).first?.deletedAt != nil)
    }

    @Test func aFinishedWatchSessionBecomesPartOfThePhonesHistory() throws {
        let workout = phone.addWorkout(named: "Leg Day")
        let planned = phone.add(try squat(in: phone), to: workout)
        planned.targetSets = 1
        planned.weight = 80
        watch.apply(phone.watchSnapshot())

        let watchWorkout = try #require(watch.workouts().first)
        var (session, engine) = watch.startSession(watchWorkout, recordedOn: .watch)
        engine.completeSet(reps: 10, weight: 80, at: .now)
        watch.finish(session, engine: engine)
        phone.apply(watch.exportSessions([session]))

        #expect(phone.history(plannedExerciseID: planned.id).map(\.sets) == [[LoggedSet(reps: 10, weight: 80)]])
        #expect(phone.lastStartedSession()?.recordedOn == .watch)
    }

    @Test func theLinkBetweenPlannedExercisesArrivesToo() throws {
        let legDay = phone.addWorkout(named: "Leg Day")
        let fullBody = phone.addWorkout(named: "Full Body")
        let squat = try squat(in: phone)
        let original = phone.add(squat, to: legDay)
        let linked = phone.add(squat, to: fullBody, linkedTo: original)

        watch.apply(phone.exportPlan())

        let received = try #require(watch.plannedExercise(id: linked.id))
        #expect(received.linkID != nil)
        #expect(received.linkID == original.linkID)
        #expect(watch.linkGroup(of: received).count == 2)
    }

    @Test func aSuggestionArrivesWithItsWeightAndRepChanges() throws {
        let workout = phone.addWorkout(named: "Leg Day")
        let planned = phone.add(try squat(in: phone), to: workout)
        let stepUp = WeightSuggestion(
            kind: .stepUp, reason: .targetHit, fromWeight: 80, toWeight: 82.5, fromReps: 8, toReps: 9)
        phone.offer(stepUp, for: planned.id, from: nil)

        watch.apply(phone.exportPlan())

        #expect(watch.pendingSuggestions().first?.suggestion == stepUp)
    }
}
