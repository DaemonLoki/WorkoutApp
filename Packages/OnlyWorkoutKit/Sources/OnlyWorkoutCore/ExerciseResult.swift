import Foundation

/// What happened to one Planned Exercise in one Session: the Target it was performed against and the Sets logged.
public struct ExerciseResult: Hashable, Codable, Sendable {
    public var date: Date
    public var target: Target
    public var sets: [LoggedSet]
    /// The Planned Exercise this came from, when known; lets statistics tell apart the same Exercise in two Workouts.
    public var plannedExerciseID: UUID?
    /// Planned Sets passed over without being performed; such a Session says nothing about a Stall.
    public var skippedSets: Int

    public init(
        date: Date, target: Target, sets: [LoggedSet], plannedExerciseID: UUID? = nil, skippedSets: Int = 0
    ) {
        self.date = date
        self.target = target
        self.sets = sets
        self.plannedExerciseID = plannedExerciseID
        self.skippedSets = skippedSets
    }

    /// Sets that count for progression: everything except extras.
    public var plannedSets: [LoggedSet] {
        sets.filter { !$0.isExtra }
    }

    /// Total reps across planned Sets; the measure a Stall compares.
    public var plannedTotalReps: Int {
        plannedSets.reduce(0) { $0 + $1.reps }
    }
}
