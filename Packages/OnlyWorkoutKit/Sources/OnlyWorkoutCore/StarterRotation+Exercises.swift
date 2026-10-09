// The Exercises of every Starter Rotation, from docs/research/training-templates.md: §5 picks the
// Exercises (the first candidate that is easy to learn and load), §3.6 the Overall Health Targets
// (compounds 3×10 @ 90 s, accessories, calves and core 2×12 @ 60 s), §2.3 the Supersets (antagonists or
// non-competing pairs, never two of the same pattern). Hard bodyweight Exercises (Pull-up, Chin-up,
// Pike Push-up) start at 8 reps, the other bodyweight compounds at 12.
extension StarterRotation {
    static func plannedExercises(for focus: Focus, _ access: EquipmentAccess) -> [PlannedExercise] {
        switch access {
        case .fullGym: fullGym(focus)
        case .dumbbellsAndBench: dumbbellsAndBench(focus)
        case .bodyweightOnly: bodyweightOnly(focus)
        }
    }

    /// A compound: 3×10 @ 90 s.
    private static func compound(_ key: String, reps: Int = 10, supersetsWithNext: Bool = false) -> PlannedExercise {
        PlannedExercise(key, sets: 3, reps: reps, restSeconds: 90, supersetsWithNext: supersetsWithNext)
    }

    /// An accessory, calves or core: 2×12 @ 60 s.
    private static func accessory(_ key: String, supersetsWithNext: Bool = false) -> PlannedExercise {
        PlannedExercise(key, sets: 2, reps: 12, restSeconds: 60, supersetsWithNext: supersetsWithNext)
    }

    private static func fullGym(_ focus: Focus) -> [PlannedExercise] {
        switch focus {
        case .fullBody:
            [
                compound("back-squat"), compound("barbell-bench-press"), compound("seated-cable-row"),
                compound("romanian-deadlift"), accessory("cable-curl", supersetsWithNext: true),
                accessory("triceps-pushdown"), accessory("cable-crunch"),
            ]
        case .upperBody:
            [
                compound("barbell-bench-press"), compound("seated-cable-row"),
                compound("seated-dumbbell-press", supersetsWithNext: true), compound("lat-pulldown"),
                accessory("lateral-raise"), accessory("dumbbell-curl", supersetsWithNext: true),
                accessory("triceps-pushdown"),
            ]
        case .lowerBody:
            [
                compound("back-squat"), compound("romanian-deadlift"), compound("bulgarian-split-squat"),
                accessory("leg-curl"), accessory("standing-calf-raise", supersetsWithNext: true),
                accessory("cable-crunch"),
            ]
        case .push:
            [
                compound("barbell-bench-press"), compound("overhead-press"), compound("incline-dumbbell-press"),
                accessory("cable-fly"), accessory("lateral-raise", supersetsWithNext: true),
                accessory("triceps-pushdown"),
            ]
        case .pull:
            [
                compound("lat-pulldown"), compound("seated-cable-row"), compound("chest-supported-row"),
                accessory("face-pull", supersetsWithNext: true), accessory("cable-curl"), accessory("hammer-curl"),
            ]
        case .legs:
            [
                compound("back-squat"), compound("romanian-deadlift"), compound("bulgarian-split-squat"),
                accessory("leg-extension", supersetsWithNext: true), accessory("leg-curl"),
                accessory("standing-calf-raise", supersetsWithNext: true), accessory("cable-crunch"),
            ]
        case .arms, .core: []
        }
    }

    private static func dumbbellsAndBench(_ focus: Focus) -> [PlannedExercise] {
        switch focus {
        case .fullBody:
            [
                compound("goblet-squat"), compound("dumbbell-bench-press", supersetsWithNext: true),
                compound("one-arm-dumbbell-row"), compound("dumbbell-romanian-deadlift"),
                accessory("dumbbell-curl", supersetsWithNext: true),
                accessory("dumbbell-overhead-triceps-extension"), accessory("dead-bug"),
            ]
        case .upperBody:
            [
                compound("dumbbell-bench-press"), compound("one-arm-dumbbell-row"),
                compound("seated-dumbbell-press", supersetsWithNext: true), compound("pull-up", reps: 8),
                accessory("lateral-raise"), accessory("dumbbell-curl", supersetsWithNext: true),
                accessory("dumbbell-overhead-triceps-extension"),
            ]
        case .lowerBody:
            [
                compound("goblet-squat"), compound("dumbbell-romanian-deadlift"), compound("bulgarian-split-squat"),
                accessory("single-leg-glute-bridge"), accessory("single-leg-calf-raise", supersetsWithNext: true),
                accessory("dead-bug"),
            ]
        case .push:
            [
                compound("dumbbell-bench-press"), compound("seated-dumbbell-press"),
                compound("incline-dumbbell-press"), accessory("dumbbell-fly"),
                accessory("lateral-raise", supersetsWithNext: true), accessory("dumbbell-overhead-triceps-extension"),
            ]
        case .pull:
            [
                compound("pull-up", reps: 8), compound("one-arm-dumbbell-row"),
                compound("chest-supported-dumbbell-row"), accessory("dumbbell-rear-delt-fly", supersetsWithNext: true),
                accessory("dumbbell-curl"), accessory("hammer-curl"),
            ]
        case .legs:
            [
                compound("goblet-squat"), compound("dumbbell-romanian-deadlift"), compound("bulgarian-split-squat"),
                accessory("single-leg-romanian-deadlift"), accessory("single-leg-calf-raise", supersetsWithNext: true),
                accessory("dead-bug"),
            ]
        case .arms, .core: []
        }
    }

    private static func bodyweightOnly(_ focus: Focus) -> [PlannedExercise] {
        switch focus {
        case .fullBody:
            [
                compound("bodyweight-squat", reps: 12), compound("push-up", reps: 12, supersetsWithNext: true),
                compound("inverted-row"), compound("split-squat", reps: 12),
                compound("single-leg-glute-bridge", reps: 12), accessory("dead-bug"),
            ]
        case .upperBody:
            [
                compound("push-up", reps: 12), compound("inverted-row"),
                compound("pike-push-up", reps: 8, supersetsWithNext: true), compound("chin-up", reps: 8),
                accessory("bench-dip"), accessory("prone-t-raise"),
            ]
        case .lowerBody:
            [
                compound("bodyweight-squat", reps: 12), compound("split-squat", reps: 12),
                compound("single-leg-glute-bridge", reps: 12),
                accessory("single-leg-calf-raise", supersetsWithNext: true), accessory("dead-bug"),
            ]
        case .push:
            [
                compound("push-up", reps: 12), compound("pike-push-up", reps: 8), compound("decline-push-up", reps: 12),
                accessory("bench-dip"),
            ]
        case .pull:
            [
                compound("pull-up", reps: 8), compound("inverted-row"), compound("chin-up", reps: 8),
                accessory("prone-t-raise"),
            ]
        case .legs:
            [
                compound("bodyweight-squat", reps: 12), compound("reverse-lunge", reps: 12),
                compound("glute-bridge", reps: 12), accessory("single-leg-calf-raise", supersetsWithNext: true),
                accessory("bicycle-crunch"),
            ]
        case .arms, .core: []
        }
    }
}
