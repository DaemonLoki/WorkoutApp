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

    /// Inserts every catalog Exercise that isn't in the store yet.
    @MainActor
    public static func seed(into context: ModelContext) throws {
        let existing = Set(try context.fetch(FetchDescriptor<Exercise>()).compactMap(\.catalogKey))
        for entry in entries where !existing.contains(entry.key) {
            context.insert(
                Exercise(
                    id: id(forKey: entry.key), name: entry.name, equipment: entry.equipment,
                    muscleGroups: entry.muscleGroups, catalogKey: entry.key))
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
    ]
}
