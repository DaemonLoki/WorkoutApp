import Foundation
import OnlyWorkoutCore
import SwiftData

/// The built-in Exercises shipped with the app (README §17).
public enum ExerciseCatalog {
    public struct Entry: Sendable {
        public let key: String
        public let name: String
        public let equipment: Equipment
        public let muscleGroups: [MuscleGroup]
    }

    /// Namespace for catalog ids: uuid5(NAMESPACE_DNS, "onlyworkout.stefanblos.com").
    static let namespace = UUID(uuidString: "b31e708d-7172-5e17-a96c-25d1fad1bc0b")!

    /// Deterministic id so a reinstall + sync merges catalog Exercises instead of duplicating them.
    public static func id(forKey key: String) -> UUID {
        UUID.version5(namespace: namespace, name: key)
    }

    /// Seeded Exercises carry this clock, so any edit that comes back from the cloud after a reinstall wins.
    static let seedDate = Date(timeIntervalSince1970: 0)

    /// Inserts every catalog Exercise that isn't in the store yet.
    @MainActor
    public static func seed(into context: ModelContext) throws {
        let existing = Set(try context.fetch(FetchDescriptor<Exercise>()).compactMap(\.catalogKey))
        for entry in entries where !existing.contains(entry.key) {
            context.insert(
                Exercise(
                    id: id(forKey: entry.key), name: entry.name, equipment: entry.equipment,
                    muscleGroups: entry.muscleGroups, catalogKey: entry.key, now: seedDate))
        }
        try context.save()
    }

    public static let entries: [Entry] = [
        Entry(
            key: "barbell-bench-press", name: "Bench Press", equipment: .barbell,
            muscleGroups: [.chest, .triceps, .shoulders]),
        Entry(
            key: "incline-dumbbell-press", name: "Incline Dumbbell Press", equipment: .dumbbell,
            muscleGroups: [.chest, .shoulders]),
        Entry(
            key: "dumbbell-bench-press", name: "Dumbbell Bench Press", equipment: .dumbbell,
            muscleGroups: [.chest, .triceps]),
        Entry(
            key: "machine-chest-press", name: "Machine Chest Press", equipment: .machine,
            muscleGroups: [.chest, .triceps]),
        Entry(key: "cable-fly", name: "Cable Fly", equipment: .cable, muscleGroups: [.chest]),
        Entry(key: "push-up", name: "Push-up", equipment: .bodyweight, muscleGroups: [.chest, .triceps]),
        Entry(key: "dip", name: "Dip", equipment: .bodyweight, muscleGroups: [.chest, .triceps]),
        Entry(key: "pull-up", name: "Pull-up", equipment: .bodyweight, muscleGroups: [.lats, .biceps]),
        Entry(key: "chin-up", name: "Chin-up", equipment: .bodyweight, muscleGroups: [.lats, .biceps]),
        Entry(key: "lat-pulldown", name: "Lat Pulldown", equipment: .cable, muscleGroups: [.lats, .biceps]),
        Entry(key: "seated-cable-row", name: "Seated Cable Row", equipment: .cable, muscleGroups: [.upperBack, .lats]),
        Entry(key: "barbell-row", name: "Barbell Row", equipment: .barbell, muscleGroups: [.upperBack, .lats]),
        Entry(
            key: "one-arm-dumbbell-row", name: "One-Arm Dumbbell Row", equipment: .dumbbell,
            muscleGroups: [.lats, .upperBack]),
        Entry(key: "chest-supported-row", name: "Chest-Supported Row", equipment: .machine, muscleGroups: [.upperBack]),
        Entry(key: "face-pull", name: "Face Pull", equipment: .cable, muscleGroups: [.shoulders, .upperBack]),
        Entry(
            key: "deadlift", name: "Deadlift", equipment: .barbell, muscleGroups: [.hamstrings, .glutes, .lowerBack]),
        Entry(
            key: "back-extension", name: "Back Extension", equipment: .bodyweight, muscleGroups: [.lowerBack, .glutes]),
        Entry(
            key: "overhead-press", name: "Overhead Press", equipment: .barbell, muscleGroups: [.shoulders, .triceps]),
        Entry(
            key: "seated-dumbbell-press", name: "Seated Dumbbell Shoulder Press", equipment: .dumbbell,
            muscleGroups: [.shoulders, .triceps]),
        Entry(key: "lateral-raise", name: "Lateral Raise", equipment: .dumbbell, muscleGroups: [.shoulders]),
        Entry(
            key: "rear-delt-fly", name: "Rear Delt Fly", equipment: .machine, muscleGroups: [.shoulders, .upperBack]),
        Entry(key: "dumbbell-shrug", name: "Dumbbell Shrug", equipment: .dumbbell, muscleGroups: [.traps]),
        Entry(key: "barbell-curl", name: "Barbell Curl", equipment: .barbell, muscleGroups: [.biceps]),
        Entry(key: "dumbbell-curl", name: "Dumbbell Curl", equipment: .dumbbell, muscleGroups: [.biceps]),
        Entry(key: "hammer-curl", name: "Hammer Curl", equipment: .dumbbell, muscleGroups: [.biceps, .forearms]),
        Entry(key: "triceps-pushdown", name: "Triceps Pushdown", equipment: .cable, muscleGroups: [.triceps]),
        Entry(
            key: "overhead-triceps-extension", name: "Overhead Triceps Extension", equipment: .cable,
            muscleGroups: [.triceps]),
        Entry(key: "skull-crusher", name: "Skull Crusher", equipment: .barbell, muscleGroups: [.triceps]),
        Entry(key: "back-squat", name: "Back Squat", equipment: .barbell, muscleGroups: [.quads, .glutes]),
        Entry(key: "front-squat", name: "Front Squat", equipment: .barbell, muscleGroups: [.quads]),
        Entry(key: "goblet-squat", name: "Goblet Squat", equipment: .kettlebell, muscleGroups: [.quads, .glutes]),
        Entry(key: "leg-press", name: "Leg Press", equipment: .machine, muscleGroups: [.quads, .glutes]),
        Entry(
            key: "romanian-deadlift", name: "Romanian Deadlift", equipment: .barbell,
            muscleGroups: [.hamstrings, .glutes]),
        Entry(
            key: "bulgarian-split-squat", name: "Bulgarian Split Squat", equipment: .dumbbell,
            muscleGroups: [.quads, .glutes]),
        Entry(key: "walking-lunge", name: "Walking Lunge", equipment: .dumbbell, muscleGroups: [.quads, .glutes]),
        Entry(key: "leg-extension", name: "Leg Extension", equipment: .machine, muscleGroups: [.quads]),
        Entry(key: "leg-curl", name: "Leg Curl", equipment: .machine, muscleGroups: [.hamstrings]),
        Entry(key: "hip-thrust", name: "Hip Thrust", equipment: .barbell, muscleGroups: [.glutes]),
        Entry(key: "hip-adduction", name: "Hip Adduction", equipment: .machine, muscleGroups: [.adductors]),
        Entry(key: "standing-calf-raise", name: "Standing Calf Raise", equipment: .machine, muscleGroups: [.calves]),
        Entry(key: "seated-calf-raise", name: "Seated Calf Raise", equipment: .machine, muscleGroups: [.calves]),
        Entry(key: "hanging-leg-raise", name: "Hanging Leg Raise", equipment: .bodyweight, muscleGroups: [.abs]),
        Entry(key: "cable-crunch", name: "Cable Crunch", equipment: .cable, muscleGroups: [.abs]),
        Entry(
            key: "ab-wheel-rollout", name: "Ab Wheel Rollout", equipment: .bodyweight, muscleGroups: [.abs, .obliques]),
        // Added in M6 for the Starter Rotations (README §17). Muscle Groups follow today's model; the M7 catalog
        // revision adds the Delt split and Secondary Muscle Groups, M8 adds Each Side.
        Entry(
            key: "incline-bench-press", name: "Incline Bench Press", equipment: .barbell,
            muscleGroups: [.chest, .shoulders]),
        Entry(
            key: "close-grip-bench-press", name: "Close-Grip Bench Press", equipment: .barbell,
            muscleGroups: [.triceps, .chest]),
        Entry(key: "pike-push-up", name: "Pike Push-up", equipment: .bodyweight, muscleGroups: [.shoulders]),
        Entry(key: "cable-lateral-raise", name: "Cable Lateral Raise", equipment: .cable, muscleGroups: [.shoulders]),
        Entry(
            key: "dumbbell-rear-delt-fly", name: "Dumbbell Rear Delt Fly", equipment: .dumbbell,
            muscleGroups: [.shoulders]),
        Entry(key: "inverted-row", name: "Inverted Row", equipment: .bodyweight, muscleGroups: [.upperBack, .lats]),
        Entry(
            key: "dumbbell-pullover", name: "Dumbbell Pullover", equipment: .dumbbell, muscleGroups: [.chest, .lats]),
        Entry(
            key: "incline-dumbbell-curl", name: "Incline Dumbbell Curl", equipment: .dumbbell, muscleGroups: [.biceps]),
        Entry(key: "cable-curl", name: "Cable Curl", equipment: .cable, muscleGroups: [.biceps]),
        Entry(
            key: "dumbbell-overhead-triceps-extension", name: "Dumbbell Overhead Triceps Extension",
            equipment: .dumbbell, muscleGroups: [.triceps]),
        Entry(key: "wrist-curl", name: "Wrist Curl", equipment: .dumbbell, muscleGroups: [.forearms]),
        Entry(
            key: "dumbbell-romanian-deadlift", name: "Dumbbell Romanian Deadlift", equipment: .dumbbell,
            muscleGroups: [.hamstrings, .glutes]),
        Entry(
            key: "single-leg-romanian-deadlift", name: "Single-Leg Romanian Deadlift", equipment: .dumbbell,
            muscleGroups: [.hamstrings, .glutes]),
        Entry(
            key: "nordic-hamstring-curl", name: "Nordic Hamstring Curl", equipment: .bodyweight,
            muscleGroups: [.hamstrings]),
        Entry(key: "step-up", name: "Step-up", equipment: .dumbbell, muscleGroups: [.quads, .glutes]),
        Entry(
            key: "copenhagen-adduction", name: "Copenhagen Adduction", equipment: .bodyweight,
            muscleGroups: [.adductors]),
        Entry(
            key: "single-leg-calf-raise", name: "Single-Leg Calf Raise", equipment: .bodyweight, muscleGroups: [.calves]
        ),
        Entry(key: "box-jump", name: "Box Jump", equipment: .bodyweight, muscleGroups: [.quads, .glutes]),
        Entry(key: "jump-squat", name: "Jump Squat", equipment: .bodyweight, muscleGroups: [.quads, .glutes]),
        Entry(
            key: "kettlebell-swing", name: "Kettlebell Swing", equipment: .kettlebell,
            muscleGroups: [.glutes, .hamstrings]),
        Entry(key: "pallof-press", name: "Pallof Press", equipment: .cable, muscleGroups: [.obliques]),
        Entry(key: "dumbbell-side-bend", name: "Dumbbell Side Bend", equipment: .dumbbell, muscleGroups: [.obliques]),
        Entry(key: "bicycle-crunch", name: "Bicycle Crunch", equipment: .bodyweight, muscleGroups: [.abs, .obliques]),
        Entry(
            key: "decline-push-up", name: "Decline Push-up", equipment: .bodyweight, muscleGroups: [.chest, .shoulders]),
        Entry(key: "dumbbell-fly", name: "Dumbbell Fly", equipment: .dumbbell, muscleGroups: [.chest]),
        Entry(key: "bench-dip", name: "Bench Dip", equipment: .bodyweight, muscleGroups: [.triceps]),
        Entry(
            key: "chest-supported-dumbbell-row", name: "Chest-Supported Dumbbell Row", equipment: .dumbbell,
            muscleGroups: [.upperBack, .lats]),
        Entry(key: "reverse-curl", name: "Reverse Curl", equipment: .barbell, muscleGroups: [.forearms, .biceps]),
        Entry(
            key: "bodyweight-squat", name: "Bodyweight Squat", equipment: .bodyweight, muscleGroups: [.quads, .glutes]),
        Entry(key: "split-squat", name: "Split Squat", equipment: .bodyweight, muscleGroups: [.quads, .glutes]),
        Entry(
            key: "single-leg-glute-bridge", name: "Single-Leg Glute Bridge", equipment: .bodyweight,
            muscleGroups: [.glutes]),
        Entry(key: "lateral-bound", name: "Lateral Bound", equipment: .bodyweight, muscleGroups: [.glutes, .quads]),
        Entry(key: "pogo-jump", name: "Pogo Jump", equipment: .bodyweight, muscleGroups: [.calves]),
        Entry(key: "plyometric-push-up", name: "Plyometric Push-up", equipment: .bodyweight, muscleGroups: [.chest]),
        Entry(key: "push-press", name: "Push Press", equipment: .barbell, muscleGroups: [.shoulders]),
        Entry(key: "crunch", name: "Crunch", equipment: .bodyweight, muscleGroups: [.abs]),
        Entry(key: "dead-bug", name: "Dead Bug", equipment: .bodyweight, muscleGroups: [.abs]),
        Entry(key: "bird-dog", name: "Bird Dog", equipment: .bodyweight, muscleGroups: [.lowerBack, .glutes]),
        Entry(key: "cable-woodchop", name: "Cable Woodchop", equipment: .cable, muscleGroups: [.obliques]),
        Entry(key: "pec-deck", name: "Pec Deck", equipment: .machine, muscleGroups: [.chest]),
        Entry(
            key: "diamond-push-up", name: "Diamond Push-up", equipment: .bodyweight, muscleGroups: [.triceps, .chest]),
        Entry(
            key: "prone-t-raise", name: "Prone T Raise", equipment: .bodyweight, muscleGroups: [.shoulders, .upperBack]),
        Entry(key: "straight-arm-pulldown", name: "Straight-Arm Pulldown", equipment: .cable, muscleGroups: [.lats]),
        Entry(key: "preacher-curl", name: "Preacher Curl", equipment: .barbell, muscleGroups: [.biceps]),
        Entry(key: "hack-squat", name: "Hack Squat", equipment: .machine, muscleGroups: [.quads, .glutes]),
        Entry(key: "good-morning", name: "Good Morning", equipment: .barbell, muscleGroups: [.hamstrings, .glutes]),
        Entry(key: "glute-bridge", name: "Glute Bridge", equipment: .bodyweight, muscleGroups: [.glutes]),
        Entry(key: "hip-abduction", name: "Hip Abduction", equipment: .machine, muscleGroups: [.glutes]),
        Entry(key: "reverse-lunge", name: "Reverse Lunge", equipment: .bodyweight, muscleGroups: [.quads, .glutes]),
    ]
}
