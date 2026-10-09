import Foundation
import OnlyWorkoutCore
import OnlyWorkoutStore

/// What a Planned Exercise row shows, as plain values, so rows can also show sample or not-yet-added plans
/// (the Welcome Tour, Starter Rotations).
struct PlannedExerciseSummary: Identifiable, Hashable {
    /// The Planned Exercise's id, or any stable value for sample and Starter Rotation rows.
    let id: String
    let name: String
    let target: Target
    var isSuperset = false
    var isLinked = false
    /// `false` while the weight is still to be chosen: the row shows Sets × reps only.
    var showsWeight = true

    init(
        id: String, name: String, target: Target, isSuperset: Bool = false, isLinked: Bool = false,
        showsWeight: Bool = true
    ) {
        self.id = id
        self.name = name
        self.target = target
        self.isSuperset = isSuperset
        self.isLinked = isLinked
        self.showsWeight = showsWeight
    }

    init(_ planned: PlannedExercise) {
        self.init(
            id: planned.id.uuidString, name: planned.exerciseName, target: planned.target,
            isSuperset: planned.supersetID != nil,
            isLinked: planned.linkID != nil)
    }
}
