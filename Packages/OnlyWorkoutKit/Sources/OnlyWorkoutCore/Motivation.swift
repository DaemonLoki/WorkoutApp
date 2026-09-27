import Foundation

/// Finds progress worth celebrating in a finished Session.
public enum Motivation {
    public static func events(for recaps: [ExerciseRecap]) -> [MotivationEvent] {
        let comeback: [MotivationEvent] = recaps.contains(where: \.cameBackAfterLayoff) ? [.comeback] : []
        return comeback
            + recaps.flatMap { recap in
                [targetEvent(for: recap), newBestEvent(for: recap)].compactMap(\.self)
            }
    }

    /// Picks one of `count` message variants, stable for a Session so a message doesn't change on re-render.
    /// - Parameter salt: Distinguishes several messages within the same Session.
    public static func variant(for sessionID: UUID, salt: Int, count: Int) -> Int {
        guard count > 1 else { return 0 }
        let bytes = withUnsafeBytes(of: sessionID.uuid) { Array($0) }
        let sum = bytes.reduce(salt) { $0 &+ Int($1) }
        return abs(sum) % count
    }

    /// An accepted Step Up, otherwise a plain Target Hit.
    private static func targetEvent(for recap: ExerciseRecap) -> MotivationEvent? {
        if let stepUp = recap.acceptedStepUp {
            return .stepUp(
                exercise: recap.exerciseName, from: stepUp.fromWeight, to: stepUp.toWeight,
                gainSinceFirst: recap.firstRecorded.map { stepUp.toWeight - $0.weight },
                firstDate: recap.firstRecorded?.date)
        }
        if Progression.isTargetHit(recap.result) {
            return .targetHit(exercise: recap.exerciseName, target: recap.result.target)
        }
        return nil
    }

    private static func newBestEvent(for recap: ExerciseRecap) -> MotivationEvent? {
        guard let previous = recap.previousBest,
            let best = recap.result.sets.max(by: { $1.beats($0) }),
            best.beats(previous)
        else { return nil }
        return .newBest(exercise: recap.exerciseName, set: LoggedSet(reps: best.reps, weight: best.weight))
    }
}
