import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// Wording of the Step Up / Step Down card, shared by iPhone and Watch.
extension SessionOffer {
    var symbol: String {
        suggestion.kind == .stepUp ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }

    var title: LocalizedStringResource {
        switch suggestion.reason {
        case .targetHit: .offerTargetHitTitle(exerciseName)
        case .stall where changesOnlyReps: .offerStallTitleReps(exerciseName, suggestion.fromReps)
        case .stall: .offerStallTitle(exerciseName, suggestion.fromWeight.kilograms)
        case .layoff: .offerLayoffTitle(exerciseName)
        }
    }

    var message: LocalizedStringResource {
        switch suggestion.reason {
        case .targetHit where suggestion.changes.count > 1:
            .offerTargetHitChoiceMessage(suggestion.toWeight.kilograms, suggestion.toReps)
        case .targetHit: .offerTargetHitMessage(suggestion.toWeight.kilograms)
        case .stall where changesOnlyReps: .offerStallMessageReps(suggestion.toReps)
        case .stall: .offerStallMessage(suggestion.toWeight.kilograms)
        case .layoff where changesOnlyReps: .offerLayoffMessageReps(suggestion.toReps)
        case .layoff: .offerLayoffMessage(suggestion.toWeight.kilograms)
        }
    }

    var declineTitle: LocalizedStringResource {
        switch suggestion.kind {
        case .stepUp: .notYet
        case .stepDown: changesOnlyReps ? .keepReps : .keepWeight
        }
    }

    /// A Step Down at 0 kg lowers the reps instead of the weight.
    private var changesOnlyReps: Bool {
        suggestion.changes == [.reps]
    }
}
