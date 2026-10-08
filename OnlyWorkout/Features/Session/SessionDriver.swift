import Foundation
import Observation
import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutLiveActivity
import OnlyWorkoutStore

/// What the Session screen needs, whether the Session runs on this iPhone (`LocalSession`)
/// or on the Watch and is mirrored here (`MirroredSession`).
protocol SessionDriver: AnyObject, Observable {
    var workoutName: String { get }
    var startedAt: Date { get }
    var engine: SessionEngine { get }
    var offer: SessionOffer? { get }
    var summary: SessionSummary? { get }
    var restEndCount: Int { get }
    var loggedSetCount: Int { get }
    var heartRate: Double? { get }
    /// Mirrored from the Watch but no state received yet.
    var isWaitingForWatch: Bool { get }

    func weightStep(for exerciseID: UUID) -> Double
    func usesAddedWeight(for exerciseID: UUID) -> Bool

    func completeSet(reps: Int, weight: Double)
    func finishRest()
    func extendRest()
    func skipSet(of exerciseID: UUID)
    func skip(_ exerciseID: UUID)
    func doLater(_ exerciseID: UUID)
    func addExtraSet(_ exerciseID: UUID)
    func editSet(exerciseID: UUID, at index: Int, reps: Int, weight: Double)
    /// - Parameter change: Which change of a Step Up to accept; `nil` for its first one.
    func answer(_ offer: SessionOffer, accept: Bool, choosing change: WeightSuggestion.Change?)
    func finish()
    /// The app came to the foreground: a good moment to start a Live Activity that couldn't start earlier.
    func appDidBecomeActive()
}

extension SessionDriver {
    func exercise(id: UUID) -> SessionEngine.Exercise? {
        engine.exercises.first { $0.id == id }
    }

    var hasRemainingSets: Bool {
        !engine.isComplete
    }

    /// e.g. "Lat Pulldown · Set 2 of 3 · 12 × 55 kg"
    var nextSetDescription: String? {
        engine.currentSet.flatMap(description(of:))
    }

    /// During the last Set of a Superset pair: what follows the Rest it starts.
    var setAfterRestDescription: String? {
        engine.setAfterRest.flatMap(description(of:))
    }

    private func description(of prompt: SessionEngine.SetPrompt) -> String? {
        guard let exercise = exercise(id: prompt.exerciseID) else { return nil }
        return String(
            localized: .nextSetDescription(
                exercise.name, prompt.setNumber, prompt.totalSets, prompt.reps, prompt.weight.kilograms))
    }

    var liveActivityState: SessionActivityAttributes.ContentState {
        guard let prompt = engine.currentSet, let exercise = exercise(id: prompt.exerciseID) else {
            return .init(
                exerciseName: workoutName, setLabel: String(localized: .allSetsDone), shortSetLabel: "✓",
                detail: "", restInterval: nil, nextUp: nil)
        }
        return .init(
            exerciseName: exercise.name,
            setLabel: String(localized: .setProgress(prompt.setNumber, prompt.totalSets)),
            shortSetLabel: "\(prompt.setNumber)/\(prompt.totalSets)",
            detail: String(localized: .repsAtWeight(prompt.reps, prompt.weight.kilograms)),
            restInterval: engine.rest.map { $0.startedAt...$0.endsAt },
            nextUp: engine.rest == nil ? nil : nextSetDescription)
    }
}

/// Identifiable wrapper so the Session can be presented with `fullScreenCover(item:)`.
struct ActiveSession: Identifiable {
    let id = UUID()
    let driver: any SessionDriver
}
