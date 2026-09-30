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
        case .stall: .offerStallTitle(exerciseName, suggestion.fromWeight.kilograms)
        case .layoff: .offerLayoffTitle(exerciseName)
        }
    }

    var message: LocalizedStringResource {
        switch suggestion.reason {
        case .targetHit: .offerTargetHitMessage(suggestion.toWeight.kilograms)
        case .stall: .offerStallMessage(suggestion.toWeight.kilograms)
        case .layoff: .offerLayoffMessage(suggestion.toWeight.kilograms)
        }
    }

    var acceptTitle: LocalizedStringResource {
        suggestion.kind == .stepUp ? .stepUp : .stepDown
    }

    var declineTitle: LocalizedStringResource {
        suggestion.kind == .stepUp ? .notYet : .keepWeight
    }
}
