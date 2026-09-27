import Foundation

/// Statistics for one Exercise across all Sessions it appeared in (README §7, Progress).
public struct ExerciseStats: Hashable, Sendable {
    /// Performed Sessions, oldest first.
    public let points: [Point]
    /// The heaviest Set, ties broken by most reps.
    public let bestSet: LoggedSet?
    /// Σ reps × weight over every Set, extras included.
    public let totalVolume: Double
    public let totalReps: Int

    /// - Parameter results: Every result of the Exercise, in any order.
    public init(results: [ExerciseResult]) {
        let performed = results.filter { !$0.sets.isEmpty }.sorted { $0.date < $1.date }
        let allSets = performed.flatMap(\.sets)
        bestSet = allSets.max { $1.beats($0) }
        totalVolume = allSets.reduce(0) { $0 + Double($1.reps) * $1.weight }
        totalReps = allSets.reduce(0) { $0 + $1.reps }

        var lastTargetWeight: [UUID?: Double] = [:]
        points = performed.map { result in
            let previous = lastTargetWeight[result.plannedExerciseID]
            lastTargetWeight[result.plannedExerciseID] = result.target.weight
            return Point(
                date: result.date,
                workingWeight: result.sets.map(\.weight).max() ?? 0,
                isStepUp: previous.map { result.target.weight > $0 } ?? false
            )
        }
    }

    /// Latest minus earliest working weight; `nil` without Sessions.
    public var weightChange: Double? {
        guard let first = points.first, let last = points.last else { return nil }
        return last.workingWeight - first.workingWeight
    }
}
