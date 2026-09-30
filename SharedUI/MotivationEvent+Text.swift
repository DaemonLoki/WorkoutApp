import Foundation
import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// Handwritten templates for progress moments, filled with real numbers (README §9).
extension MotivationEvent {
    var symbol: String {
        switch self {
        case .stepUp: "arrow.up.circle.fill"
        case .targetHit: "target"
        case .newBest: "star.fill"
        case .comeback: "hand.wave.fill"
        }
    }

    /// - Parameter variant: 0 or 1, from `Motivation.variant`, so messages don't repeat every time.
    func title(variant: Int) -> LocalizedStringResource {
        switch self {
        case .stepUp(let exercise, _, _, _, _): .eventStepUpTitle(exercise)
        case .targetHit(let exercise, _):
            variant == 0 ? .eventTargetHitTitle0(exercise) : .eventTargetHitTitle1(exercise)
        case .newBest(let exercise, _): .eventNewBestTitle(exercise)
        case .comeback: variant == 0 ? .eventComebackTitle0 : .eventComebackTitle1
        }
    }

    var message: LocalizedStringResource {
        switch self {
        case .stepUp(_, let from, let to, let gain, let firstDate):
            if let gain, let firstDate, gain > to - from {
                .eventStepUpMessageSince(
                    from.kilograms, to.kilograms, gain.kilogramsChange, firstDate.formatted(.dateTime.month(.wide)))
            } else {
                .eventStepUpMessage(from.kilograms, to.kilograms)
            }
        case .targetHit(_, let target):
            .eventTargetHitMessage(target.sets, target.reps, target.weight.kilograms)
        case .newBest(_, let set):
            .eventNewBestMessage(set.reps, set.weight.kilograms)
        case .comeback:
            .eventComebackMessage
        }
    }
}
