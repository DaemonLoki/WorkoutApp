import Testing

@testable import OnlyWorkoutCore

@Suite("Rotation")
struct RotationTests {
    let workouts = ["Push", "Pull", "Legs"]

    @Test func nextUpIsTheWorkoutAfterTheMostRecentlyStartedOne() {
        #expect(Rotation.nextUp(in: workouts, lastStarted: "Push") == "Pull")
        #expect(Rotation.nextUp(in: workouts, lastStarted: "Pull") == "Legs")
    }

    @Test func theRotationWrapsAroundAfterTheLastWorkout() {
        #expect(Rotation.nextUp(in: workouts, lastStarted: "Legs") == "Push")
    }

    @Test func withoutSessionsOrAfterADeletedWorkoutTheFirstWorkoutIsNextUp() {
        #expect(Rotation.nextUp(in: workouts, lastStarted: nil) == "Push")
        #expect(Rotation.nextUp(in: workouts, lastStarted: "Deleted") == "Push")
        #expect(Rotation.nextUp(in: [String](), lastStarted: nil) == nil)
    }
}
