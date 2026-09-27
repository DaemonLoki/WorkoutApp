import Foundation

/// Progressive-overload rules (README §4, ADR-0003).
public enum Progression {
    /// Consecutive missed Sessions at the same weight, without a new best total, that make a Stall.
    public static let stallSessionCount = 3

    /// Time away from a Planned Exercise after which it counts as a Layoff.
    public static let layoffInterval: TimeInterval = 21 * 86_400

    public static func isTargetHit(_ result: ExerciseResult) -> Bool {
        let planned = result.plannedSets
        return planned.count >= result.target.sets
            && planned.allSatisfy { $0.reps >= result.target.reps && $0.weight == result.target.weight }
    }

    /// Whether the most recent Sessions form a Stall at `currentWeight`: all missed the Target at that weight
    /// and none beat the first one's total reps.
    /// - Parameter history: Results of the Planned Exercise, oldest first.
    public static func isStall(history: [ExerciseResult], currentWeight: Double) -> Bool {
        let window = history.suffix(stallSessionCount)
        guard let first = window.first, window.count == stallSessionCount,
            window.allSatisfy({ $0.target.weight == currentWeight && !isTargetHit($0) })
        else { return false }

        return window.dropFirst().allSatisfy { $0.plannedTotalReps <= first.plannedTotalReps }
    }

    /// The suggestion to offer after the latest Session of a Planned Exercise.
    /// - Parameter history: Results of the Planned Exercise, oldest first, ending with the latest Session.
    public static func suggestion(history: [ExerciseResult], currentWeight: Double, weightStep: Double)
        -> WeightSuggestion?
    {
        guard let latest = history.last else { return nil }
        if isTargetHit(latest) {
            return WeightSuggestion(
                kind: .stepUp, reason: .targetHit, fromWeight: currentWeight, toWeight: currentWeight + weightStep)
        }
        if isStall(history: history, currentWeight: currentWeight) {
            return stepDown(from: currentWeight, by: weightStep, reason: .stall)
        }
        return nil
    }

    /// The Step Down to offer before the first Set when a Planned Exercise comes back after a Layoff.
    public static func layoffSuggestion(
        lastPerformed: Date?, now: Date, currentWeight: Double, weightStep: Double
    ) -> WeightSuggestion? {
        guard let lastPerformed, now.timeIntervalSince(lastPerformed) > layoffInterval else { return nil }
        return stepDown(from: currentWeight, by: weightStep, reason: .layoff)
    }

    private static func stepDown(from weight: Double, by step: Double, reason: WeightSuggestion.Reason)
        -> WeightSuggestion?
    {
        guard weight > 0 else { return nil }
        return WeightSuggestion(kind: .stepDown, reason: reason, fromWeight: weight, toWeight: max(0, weight - step))
    }
}
