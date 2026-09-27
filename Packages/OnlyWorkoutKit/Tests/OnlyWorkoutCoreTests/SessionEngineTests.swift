import Foundation
import Testing

@testable import OnlyWorkoutCore

@Suite("SessionEngine")
struct SessionEngineTests {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    func exercise(
        _ name: String, sets: Int = 3, reps: Int = 10, weight: Double = 50, rest: Int = 90, superset: UUID? = nil
    ) -> SessionEngine.Exercise {
        SessionEngine.Exercise(
            id: UUID(), name: name, target: Target(sets: sets, reps: reps, weight: weight),
            restSeconds: rest, supersetID: superset)
    }

    @Test func aNewSessionPromptsTheFirstSetOfTheFirstExercisePrefilledWithItsTarget() {
        let bench = exercise("Bench Press", reps: 8, weight: 60)
        let engine = SessionEngine(exercises: [bench, exercise("Row")])

        #expect(
            engine.currentSet
                == SessionEngine.SetPrompt(
                    exerciseID: bench.id, setNumber: 1, totalSets: 3, reps: 8, weight: 60, isExtra: false))
        #expect(engine.rest == nil)
    }

    @Test func completingASetLogsItAndStartsRestThenTheNextSetFollows() {
        let bench = exercise("Bench Press", rest: 120)
        var engine = SessionEngine(exercises: [bench])

        engine.completeSet(reps: 9, weight: 50, at: start)

        #expect(engine.exercises[0].sets == [LoggedSet(reps: 9, weight: 50)])
        #expect(engine.rest == SessionEngine.Rest(startedAt: start, duration: 120))

        engine.finishRest()

        #expect(engine.rest == nil)
        #expect(engine.currentSet?.setNumber == 2)
    }

    @Test func afterTheLastPlannedSetTheNextExerciseFollowsAndTheFinishIsReported() {
        let curl = exercise("Curl", sets: 2)
        let pushdown = exercise("Pushdown", sets: 1)
        var engine = SessionEngine(exercises: [curl, pushdown])

        let first = engine.completeSet(reps: 10, weight: 50, at: start)
        engine.finishRest()
        let second = engine.completeSet(reps: 10, weight: 50, at: start)

        #expect(first?.finishedPlannedSets == false)
        #expect(second == SessionEngine.CompletedSet(exerciseID: curl.id, finishedPlannedSets: true))
        #expect(engine.rest != nil)

        engine.finishRest()
        #expect(engine.currentSet?.exerciseID == pushdown.id)

        engine.completeSet(reps: 10, weight: 50, at: start)
        #expect(engine.rest == nil)
        #expect(engine.currentSet == nil)
        #expect(engine.isComplete)
    }

    @Test func aSupersetAlternatesAndRestsAfterEachPairForTheLongerRest() {
        let pair = UUID()
        let curl = exercise("Curl", sets: 2, rest: 60, superset: pair)
        let pushdown = exercise("Pushdown", sets: 2, rest: 90, superset: pair)
        var engine = SessionEngine(exercises: [curl, pushdown])
        var order: [UUID] = []
        var restsAfter: [TimeInterval?] = []

        while let prompt = engine.currentSet {
            order.append(prompt.exerciseID)
            engine.completeSet(reps: 10, weight: 50, at: start)
            restsAfter.append(engine.rest?.duration)
            engine.finishRest()
        }

        #expect(order == [curl.id, pushdown.id, curl.id, pushdown.id])
        #expect(restsAfter == [nil, 90, nil, nil])
    }

    /// Performs every remaining Set with its prefilled values, returning the exercise order and Rest after each.
    func performAll(_ engine: inout SessionEngine) -> (order: [UUID], rests: [TimeInterval?]) {
        var order: [UUID] = []
        var rests: [TimeInterval?] = []
        while let prompt = engine.currentSet {
            order.append(prompt.exerciseID)
            engine.completeSet(reps: prompt.reps, weight: prompt.weight, at: start)
            rests.append(engine.rest?.duration)
            engine.finishRest()
        }
        return (order, rests)
    }

    @Test func theLongerHalfOfAnUnevenSupersetContinuesAloneWithRestAfterEachSet() {
        let pair = UUID()
        let a = exercise("A", sets: 3, rest: 60, superset: pair)
        let b = exercise("B", sets: 1, rest: 60, superset: pair)
        let c = exercise("C", sets: 1, rest: 30)
        var engine = SessionEngine(exercises: [a, b, c])

        let (order, rests) = performAll(&engine)

        #expect(order == [a.id, b.id, a.id, a.id, c.id])
        #expect(rests == [nil, 60, 60, 60, nil])
    }

    @Test func aSkippedExerciseIsLeftOutOfTheQueue() {
        let bench = exercise("Bench Press", sets: 1)
        let row = exercise("Row", sets: 1)
        var engine = SessionEngine(exercises: [bench, row])

        engine.skip(bench.id)

        #expect(engine.currentSet?.exerciseID == row.id)
        #expect(engine.exercises[0].status == .skipped)
    }

    @Test func doLaterMovesTheExerciseAndItsSupersetPartnerToTheEnd() {
        let pair = UUID()
        let a = exercise("A", sets: 1, superset: pair)
        let b = exercise("B", sets: 1, superset: pair)
        let c = exercise("C", sets: 1)
        var engine = SessionEngine(exercises: [a, b, c])

        engine.doLater(b.id)

        #expect(engine.exercises.map(\.id) == [c.id, a.id, b.id])
        #expect(performAll(&engine).order == [c.id, a.id, b.id])
    }

    @Test func anExtraSetIsPromptedAsExtraAndLoggedAsExtra() {
        let bench = exercise("Bench Press", sets: 1, reps: 8, weight: 60)
        var engine = SessionEngine(exercises: [bench])
        engine.completeSet(reps: 8, weight: 60, at: start)

        engine.addExtraSet(bench.id)

        #expect(
            engine.currentSet
                == SessionEngine.SetPrompt(
                    exerciseID: bench.id, setNumber: 2, totalSets: 2, reps: 8, weight: 60, isExtra: true))

        let completed = engine.completeSet(reps: 6, weight: 60, at: start)

        #expect(completed?.finishedPlannedSets == false)
        #expect(engine.exercises[0].sets.last == LoggedSet(reps: 6, weight: 60, isExtra: true))
        #expect(engine.isComplete)
    }

    @Test func theNextSetIsPrefilledWithTheWeightLastUsedForThatExercise() {
        let bench = exercise("Bench Press", reps: 8, weight: 60)
        var engine = SessionEngine(exercises: [bench])

        engine.completeSet(reps: 6, weight: 57.5, at: start)

        #expect(engine.currentSet?.weight == 57.5)
        #expect(engine.currentSet?.reps == 8)
    }

    @Test func aLoggedSetCanBeCorrected() {
        let bench = exercise("Bench Press", sets: 2)
        var engine = SessionEngine(exercises: [bench])
        engine.completeSet(reps: 10, weight: 50, at: start)

        engine.editSet(exerciseID: bench.id, at: 0, reps: 8, weight: 52.5)

        #expect(engine.exercises[0].sets == [LoggedSet(reps: 8, weight: 52.5)])
    }

    @Test func changingTheTargetWeightUpdatesThisSessionsTargetAndPrefill() {
        let squat = exercise("Squat", weight: 60)
        var engine = SessionEngine(exercises: [squat])

        engine.setTargetWeight(57.5, for: squat.id)

        #expect(engine.exercises[0].target.weight == 57.5)
        #expect(engine.currentSet?.weight == 57.5)
    }

    @Test func restCanBeExtended() {
        var engine = SessionEngine(exercises: [exercise("Bench Press", rest: 90)])
        engine.completeSet(reps: 10, weight: 50, at: start)

        engine.extendRest(by: 30)

        #expect(engine.rest?.duration == 120)
    }

    @Test func endingEarlyStopsTheQueueAndLeavesUnfinishedExercisesPending() {
        let bench = exercise("Bench Press", sets: 2)
        let row = exercise("Row")
        var engine = SessionEngine(exercises: [bench, row])
        engine.completeSet(reps: 10, weight: 50, at: start)

        engine.end()

        #expect(engine.isEnded)
        #expect(engine.currentSet == nil)
        #expect(engine.rest == nil)
        #expect(engine.exercises.map(\.status) == [.pending, .pending])
    }

    @Test func aSessionInProgressSurvivesEncodingSoItCanBeResumed() throws {
        var engine = SessionEngine(exercises: [exercise("Bench Press"), exercise("Row")])
        engine.completeSet(reps: 10, weight: 50, at: start)

        let restored = try JSONDecoder().decode(SessionEngine.self, from: JSONEncoder().encode(engine))

        #expect(restored == engine)
    }

    @Test func aFinishedExerciseBecomesAResultForProgression() {
        let bench = exercise("Bench Press", sets: 2, reps: 8, weight: 60)
        var engine = SessionEngine(exercises: [bench])
        engine.completeSet(reps: 8, weight: 60, at: start)
        engine.completeSet(reps: 9, weight: 60, at: start)

        let result = engine.exercises[0].result(on: start)

        #expect(result == ExerciseResult(date: start, target: bench.target, sets: engine.exercises[0].sets))
        #expect(Progression.isTargetHit(result))
    }
}
