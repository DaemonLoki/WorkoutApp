import Foundation

/// Runs one Session: builds the queue of Sets from the Workout and processes events (README §6).
/// Pure value type so the same engine drives iPhone and Watch and can be persisted to resume a Session.
public struct SessionEngine: Hashable, Codable, Sendable {
    /// Session Exercises in queue order; Superset partners are adjacent.
    public private(set) var exercises: [Exercise]
    public private(set) var rest: Rest?
    /// The Session was ended, possibly early.
    public private(set) var isEnded = false

    public init(exercises: [Exercise]) {
        self.exercises = exercises
    }

    /// The next Set to perform, prefilled; `nil` when nothing is left.
    public var currentSet: SetPrompt? {
        guard let index = currentIndex else { return nil }
        let exercise = exercises[index]
        return SetPrompt(
            exerciseID: exercise.id, setNumber: exercise.progress + 1, totalSets: exercise.totalSets,
            reps: exercise.target.reps, weight: exercise.sets.last?.weight ?? exercise.target.weight,
            isExtra: exercise.nextSetIsExtra)
    }

    /// Every Set is logged (skipped exercises owe none).
    public var isComplete: Bool {
        exercises.allSatisfy { $0.remainingSets == 0 }
    }

    /// Logs the current Set and starts Rest, except between the two halves of a Superset round
    /// and after the Session's final Set.
    /// - Returns: `nil` if there was no Set to perform.
    @discardableResult
    public mutating func completeSet(reps: Int, weight: Double, at date: Date) -> CompletedSet? {
        guard let index = currentIndex else { return nil }
        let isExtra = exercises[index].nextSetIsExtra
        exercises[index].sets.append(LoggedSet(reps: reps, weight: weight, isExtra: isExtra))
        let exercise = exercises[index]

        rest = restDuration(after: index).map { Rest(startedAt: date, duration: $0) }
        return CompletedSet(
            exerciseID: exercise.id, finishedPlannedSets: !isExtra && exercise.progress == exercise.target.sets)
    }

    public mutating func finishRest() {
        rest = nil
    }

    public mutating func extendRest(by interval: TimeInterval) {
        rest?.duration += interval
    }

    /// Ends the Session; anything not performed stays pending.
    public mutating func end() {
        isEnded = true
        rest = nil
    }

    /// Passes over the current Set of an exercise without performing it; no Rest follows.
    public mutating func skipSet(of exerciseID: UUID) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseID }), exercises[index].remainingSets > 0
        else { return }
        exercises[index].skippedSets += 1
        rest = nil
    }

    public mutating func skip(_ exerciseID: UUID) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        exercises[index].isSkipped = true
    }

    /// Corrects a logged Set (0-based `setIndex`).
    public mutating func editSet(exerciseID: UUID, at setIndex: Int, reps: Int, weight: Double) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseID }),
            exercises[index].sets.indices.contains(setIndex)
        else { return }
        exercises[index].sets[setIndex].reps = reps
        exercises[index].sets[setIndex].weight = weight
    }

    /// Changes this Session's Target weight for an exercise, e.g. after accepting a Layoff Step Down.
    public mutating func setTargetWeight(_ weight: Double, for exerciseID: UUID) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        exercises[index].target.weight = weight
    }

    /// Requests one more Set beyond the Target.
    public mutating func addExtraSet(_ exerciseID: UUID) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        exercises[index].extraSets += 1
        exercises[index].isSkipped = false
    }

    /// Moves the exercise's block (the exercise, or its whole Superset) to the end of the queue.
    public mutating func doLater(_ exerciseID: UUID) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseID }),
            let block = blocks.first(where: { $0.contains(index) })
        else { return }
        let moved = block.map { exercises[$0] }
        exercises.removeSubrange(block[0]...block[block.count - 1])
        exercises.append(contentsOf: moved)
    }

    // MARK: - Queue

    /// Indices of `exercises` grouped into blocks: a Superset pair or a single exercise.
    private var blocks: [[Int]] {
        var blocks: [[Int]] = []
        for index in exercises.indices {
            if let supersetID = exercises[index].supersetID, let last = blocks.last?.last,
                exercises[last].supersetID == supersetID
            {
                blocks[blocks.count - 1].append(index)
            } else {
                blocks.append([index])
            }
        }
        return blocks
    }

    /// The first block with work left; inside a Superset, the partner with fewer Sets goes next (A1, B1, A2, …).
    private var currentIndex: Int? {
        guard !isEnded else { return nil }
        for block in blocks {
            let open = block.filter { exercises[$0].remainingSets > 0 }
            if let next = open.min(by: { exercises[$0].progress < exercises[$1].progress }) {
                return next
            }
        }
        return nil
    }

    /// `nil` when no Rest follows the Set just logged at `index`.
    private func restDuration(after index: Int) -> TimeInterval? {
        guard let next = currentIndex else { return nil }
        guard let block = blocks.first(where: { $0.contains(index) }), block.count > 1 else {
            return TimeInterval(exercises[index].restSeconds)
        }
        let partnerOwesThisRound =
            next != index && block.contains(next)
            && exercises[next].progress < exercises[index].progress
        if partnerOwesThisRound { return nil }
        return TimeInterval(block.map { exercises[$0].restSeconds }.max() ?? exercises[index].restSeconds)
    }
}
