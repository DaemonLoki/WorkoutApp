import Foundation

/// Progressive-overload rules (README §4, ADR-0003).
public enum Progression {
    /// Consecutive missed Sessions at the same Target, without a new best total, that make a Stall.
    public static let stallSessionCount = 3

    /// Time away from a Planned Exercise after which it counts as a Layoff.
    public static let layoffInterval: TimeInterval = 21 * 86_400

    public static func isTargetHit(_ result: ExerciseResult) -> Bool {
        let planned = result.plannedSets
        return planned.count >= result.target.sets
            && planned.allSatisfy { $0.reps >= result.target.reps && $0.weight == result.target.weight }
    }

    /// Whether the most recent Sessions form a Stall at the `current` Target: all missed it at that weight
    /// and reps, and none beat the first one's total reps.
    /// - Parameter history: Results of the Planned Exercise, oldest first.
    /// Sessions with a skipped Set (e.g. the machine was taken) don't count, like skipped exercises.
    public static func isStall(history: [ExerciseResult], current: Target) -> Bool {
        let window = history.filter { $0.skippedSets == 0 }.suffix(stallSessionCount)
        guard let first = window.first, window.count == stallSessionCount,
            window.allSatisfy({
                $0.target.weight == current.weight && $0.target.reps == current.reps && !isTargetHit($0)
            })
        else { return false }

        return window.dropFirst().allSatisfy { $0.plannedTotalReps <= first.plannedTotalReps }
    }

    /// The suggestion to offer after the latest Session of a Planned Exercise.
    /// - Parameters:
    ///   - history: Results of the Planned Exercise, oldest first, ending with the latest Session.
    ///   - current: The Planned Exercise's Target now.
    public static func suggestion(history: [ExerciseResult], current: Target, weightStep: Double)
        -> WeightSuggestion?
    {
        guard let latest = history.last else { return nil }
        if isTargetHit(latest) {
            return WeightSuggestion(
                kind: .stepUp, reason: .targetHit, fromWeight: current.weight, toWeight: current.weight + weightStep,
                fromReps: current.reps, toReps: min(current.reps + 1, PlanDefaults.repsRange.upperBound))
        }
        if isStall(history: history, current: current) {
            return stepDown(from: current, by: weightStep, reason: .stall)
        }
        return nil
    }

    /// The Step Down to offer before the first Set when a Planned Exercise comes back after a Layoff.
    public static func layoffSuggestion(
        lastPerformed: Date?, now: Date, current: Target, weightStep: Double
    ) -> WeightSuggestion? {
        guard let lastPerformed, now.timeIntervalSince(lastPerformed) > layoffInterval else { return nil }
        return stepDown(from: current, by: weightStep, reason: .layoff)
    }

    /// One Weight Step lighter; at 0 kg (e.g. a bodyweight Exercise) one rep fewer instead.
    private static func stepDown(from current: Target, by step: Double, reason: WeightSuggestion.Reason)
        -> WeightSuggestion?
    {
        var suggestion = WeightSuggestion(
            kind: .stepDown, reason: reason, fromWeight: current.weight, toWeight: current.weight,
            fromReps: current.reps, toReps: current.reps)
        if current.weight > 0 {
            suggestion.toWeight = max(0, current.weight - step)
        } else if current.reps > PlanDefaults.repsRange.lowerBound {
            suggestion.toReps = current.reps - 1
        } else {
            return nil
        }
        return suggestion
    }
}
