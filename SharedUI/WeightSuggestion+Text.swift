import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// Wording of a suggestion's choices, shared by the Session card (iPhone and Watch) and Today.
extension WeightSuggestion {
    /// The changes on offer, the prominent one first: reps for bodyweight Exercises, weight otherwise.
    func choices(prefersReps: Bool) -> [Change] {
        prefersReps ? changes.sorted { $0 == .reps && $1 != .reps } : changes
    }

    func acceptTitle(for change: Change) -> LocalizedStringResource {
        switch (kind, change) {
        case (.stepUp, .weight): .stepUpTo(toWeight.kilograms)
        case (.stepUp, .reps): .stepUpToReps(toReps)
        case (.stepDown, .weight): .stepDownTo(toWeight.kilograms)
        case (.stepDown, .reps): .stepDownToReps(toReps)
        }
    }
}
