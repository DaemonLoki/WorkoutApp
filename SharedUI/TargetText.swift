import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

extension Target {
    /// e.g. "3 × 12 · 40 kg"
    var summary: LocalizedStringResource {
        .targetSummary(sets, reps, weight.kilograms)
    }
}
