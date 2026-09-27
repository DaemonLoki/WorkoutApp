import Foundation

/// Everything needed to find progress worth celebrating for one exercise of a finished Session.
public struct ExerciseRecap: Sendable {
    public var exerciseName: String
    public var result: ExerciseResult
    /// Best Set across earlier Sessions of this Exercise; `nil` on its first Session.
    public var previousBest: LoggedSet?
    /// The Step Up accepted in this Session, if any.
    public var acceptedStepUp: WeightSuggestion?
    /// The earliest recorded Target weight of this Exercise, for "+10 kg since June".
    public var firstRecorded: (date: Date, weight: Double)?
    public var cameBackAfterLayoff: Bool

    public init(
        exerciseName: String, result: ExerciseResult, previousBest: LoggedSet?, acceptedStepUp: WeightSuggestion?,
        firstRecorded: (date: Date, weight: Double)?, cameBackAfterLayoff: Bool
    ) {
        self.exerciseName = exerciseName
        self.result = result
        self.previousBest = previousBest
        self.acceptedStepUp = acceptedStepUp
        self.firstRecorded = firstRecorded
        self.cameBackAfterLayoff = cameBackAfterLayoff
    }
}
