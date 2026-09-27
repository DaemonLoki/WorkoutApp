import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// The Step Up / Step Down question, shown during Rest (or before the first Set after a Layoff).
struct OfferCard: View {
    let offer: SessionController.Offer
    let onAnswer: (_ accept: Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            Label {
                Text(title).font(.headline)
            } icon: {
                Image(systemName: offer.suggestion.kind == .stepUp ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundStyle(.tint)
            }
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: DesignTokens.Spacing.s) {
                Button {
                    onAnswer(true)
                } label: {
                    Text(acceptTitle).frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .accessibilityIdentifier("acceptOfferButton")
                Button {
                    onAnswer(false)
                } label: {
                    Text(declineTitle).frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .accessibilityIdentifier("declineOfferButton")
            }
            .controlSize(.large)
        }
        .padding(DesignTokens.Spacing.m)
        .glassEffect(in: .rect(cornerRadius: DesignTokens.Radius.card))
    }

    private var suggestion: WeightSuggestion { offer.suggestion }

    private var title: LocalizedStringResource {
        switch suggestion.reason {
        case .targetHit: .offerTargetHitTitle(offer.exerciseName)
        case .stall: .offerStallTitle(offer.exerciseName, suggestion.fromWeight.kilograms)
        case .layoff: .offerLayoffTitle(offer.exerciseName)
        }
    }

    private var message: LocalizedStringResource {
        switch suggestion.reason {
        case .targetHit: .offerTargetHitMessage(suggestion.toWeight.kilograms)
        case .stall: .offerStallMessage(suggestion.toWeight.kilograms)
        case .layoff: .offerLayoffMessage(suggestion.toWeight.kilograms)
        }
    }

    private var acceptTitle: LocalizedStringResource {
        suggestion.kind == .stepUp ? .stepUp : .stepDown
    }

    private var declineTitle: LocalizedStringResource {
        suggestion.kind == .stepUp ? .notYet : .keepWeight
    }
}
