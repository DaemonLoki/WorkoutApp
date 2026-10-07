import Testing

@testable import OnlyWorkoutCore

@Suite("StravaExerciseGroup")
struct StravaExerciseGroupTests {
    /// Strava's page lists 656 identifiers in 34 groups, none of them twice (2026-10-03).
    @Test func stravasListHas656TypesIn34Groups() {
        let types = StravaExerciseGroup.all.flatMap(\.types)

        #expect(StravaExerciseGroup.all.count == 34)
        #expect(types.count == 656)
        #expect(Set(types).count == 656)
    }

    @Test func onlyTypesFromStravasListAreKnown() {
        #expect(StravaExerciseGroup.isKnown("MACHINE_CHEST_PRESS"))
        #expect(!StravaExerciseGroup.isKnown("MACHINE_CHEST_PRES"))
        #expect(!StravaExerciseGroup.isKnown("machine_chest_press"))
    }

    @Test func aTypeReadsAsWordsInThePicker() {
        #expect(StravaExerciseGroup.displayName(of: "CABLE_TRICEPS_PUSHDOWN") == "Cable Triceps Pushdown")
        #expect(StravaExerciseGroup.displayName(of: "PUSH_UP_GENERIC") == "Push Up (Generic)")
    }
}
