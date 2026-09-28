import Foundation
import OnlyWorkoutCore
import SwiftData
import Testing

@testable import OnlyWorkoutStore

/// The Session orchestration shared by iPhone and Watch (README §4, §6).
@Suite("SessionRunner")
@MainActor
struct SessionRunnerTests {
    let container: ModelContainer
    var log: TrainingLog { TrainingLog(context: container.mainContext) }
    let squat: PlannedExercise
    let workout: Workout

    init() throws {
        container = try StoreContainer.make(inMemory: true)
        try ExerciseCatalog.seed(into: container.mainContext)
        let log = TrainingLog(context: container.mainContext)
        let key = "back-squat"
        let exercise = try #require(
            try log.context.fetch(FetchDescriptor<Exercise>(predicate: #Predicate { $0.catalogKey == key })).first)
        workout = log.addWorkout(named: "Leg Day")
        squat = log.add(exercise, to: workout)
        squat.targetSets = 2
        squat.targetReps = 5
        squat.weight = 80
        squat.weightStep = 2.5
    }

    func runner(startedAt: Date = .now) -> SessionRunner {
        let (session, engine) = log.startSession(workout, now: startedAt)
        return SessionRunner(session: session, engine: engine, log: log, now: { startedAt })
    }

    @Test func aTargetHitOffersAStepUpAfterTheLastPlannedSetAndAcceptingRaisesTheWeight() throws {
        let runner = runner()

        runner.completeSet(reps: 5, weight: 80)
        #expect(runner.offer == nil)
        runner.completeSet(reps: 6, weight: 80)

        let offer = try #require(runner.offer)
        #expect(offer.suggestion == WeightSuggestion(kind: .stepUp, reason: .targetHit, fromWeight: 80, toWeight: 82.5))

        runner.answer(offer, accept: true)

        #expect(runner.offer == nil)
        #expect(squat.weight == 82.5)
    }

    @Test func aDeclinedStepUpStaysPendingForTheTodayScreen() throws {
        let runner = runner()
        runner.completeSet(reps: 5, weight: 80)
        runner.completeSet(reps: 5, weight: 80)

        runner.answer(try #require(runner.offer), accept: false)

        #expect(squat.weight == 80)
        #expect(log.pendingSuggestions().map(\.suggestion.toWeight) == [82.5])
    }

    @Test func aLayoffOffersAStepDownBeforeTheFirstSetThatLowersThisSessionsTarget() throws {
        let fiveWeeksAgo = Date.now.addingTimeInterval(-35 * 86_400)
        let earlier = runner(startedAt: fiveWeeksAgo)
        earlier.completeSet(reps: 4, weight: 80)
        earlier.finish()

        let runner = runner()
        let offer = try #require(runner.offer)
        #expect(offer.suggestion == WeightSuggestion(kind: .stepDown, reason: .layoff, fromWeight: 80, toWeight: 77.5))
        #expect(runner.engine.exercises[0].sets.isEmpty)

        runner.answer(offer, accept: true)

        #expect(runner.engine.currentSet?.weight == 77.5)
        #expect(squat.weight == 77.5)
    }

    @Test func theSummaryCelebratesAnAcceptedStepUp() throws {
        let runner = runner()
        runner.completeSet(reps: 5, weight: 80)
        runner.completeSet(reps: 5, weight: 80)
        runner.answer(try #require(runner.offer), accept: true)

        runner.finish()

        let summary = try #require(runner.summary)
        #expect(summary.setCount == 2)
        #expect(summary.events.contains { if case .stepUp = $0 { true } else { false } })
        #expect(runner.session.endedAt != nil)
    }
}
