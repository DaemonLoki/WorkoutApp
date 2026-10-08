import Foundation
import Testing

@testable import OnlyWorkoutCore

@Suite("Motivation")
struct MotivationTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let target = Target(sets: 2, reps: 10, weight: 60)

    func recap(
        _ name: String = "Squat", reps: [Int] = [10, 10], weight: Double = 60,
        previousBest: LoggedSet? = nil, stepUp: WeightSuggestion? = nil,
        firstWeight: Double? = nil, afterLayoff: Bool = false
    ) -> ExerciseRecap {
        ExerciseRecap(
            exerciseName: name,
            result: ExerciseResult(date: now, target: target, sets: reps.map { LoggedSet(reps: $0, weight: weight) }),
            previousBest: previousBest,
            acceptedStepUp: stepUp,
            firstRecorded: firstWeight.map { (date: now.addingTimeInterval(-90 * 86_400), weight: $0) },
            cameBackAfterLayoff: afterLayoff
        )
    }

    @Test func anAcceptedStepUpIsCelebratedInsteadOfItsTargetHit() {
        let stepUp = WeightSuggestion(
            kind: .stepUp, reason: .targetHit, fromWeight: 60, toWeight: 62.5, fromReps: 10, toReps: 10)

        let events = Motivation.events(for: [recap(stepUp: stepUp, firstWeight: 52.5)])

        #expect(
            events == [
                .stepUp(
                    exercise: "Squat", from: 60, to: 62.5, gainSinceFirst: 10,
                    firstDate: now.addingTimeInterval(-90 * 86_400))
            ])
    }

    @Test func aTargetHitWithoutAcceptedStepUpIsCelebratedAndAMissIsNot() {
        let events = Motivation.events(for: [recap("Squat"), recap("Row", reps: [10, 8])])

        #expect(events == [.targetHit(exercise: "Squat", target: target)])
    }

    @Test func beatingThePreviousBestSetIsANewBestButAFirstSessionIsNot() {
        let beaten = recap("Pull-up", reps: [12, 9], weight: 5, previousBest: LoggedSet(reps: 11, weight: 5))
        let matched = recap("Row", reps: [8, 8], weight: 60, previousBest: LoggedSet(reps: 8, weight: 60))
        let first = recap("Curl", reps: [8, 8], weight: 20)

        let events = Motivation.events(for: [beaten, matched, first])

        #expect(events == [.newBest(exercise: "Pull-up", set: LoggedSet(reps: 12, weight: 5))])
    }

    @Test func comingBackAfterALayoffIsWelcomedOnceFirst() {
        let events = Motivation.events(for: [
            recap("Squat", reps: [8, 8], afterLayoff: true), recap("Row", reps: [8, 8], afterLayoff: true),
        ])

        #expect(events == [.comeback])
    }

    @Test func theMessageVariantIsStableForASessionAndWithinRange() {
        let session = UUID(uuidString: "6F9619FF-8B86-D011-B42D-00C04FC964FF")!
        let variants = (0..<5).map { _ in Motivation.variant(for: session, salt: 2, count: 3) }

        #expect(Set(variants).count == 1)
        #expect((0..<3).contains(variants[0]))
        #expect(Motivation.variant(for: session, salt: 0, count: 1) == 0)
    }

    @Test func anAcceptedRepStepUpIsCelebratedWithItsReps() {
        let stepUp = WeightSuggestion(
            kind: .stepUp, reason: .targetHit, fromWeight: 60, toWeight: 60, fromReps: 10, toReps: 11)

        let events = Motivation.events(for: [recap(stepUp: stepUp, firstWeight: 52.5)])

        #expect(events == [.repStepUp(exercise: "Squat", sets: 2, fromReps: 10, toReps: 11)])
    }
}
