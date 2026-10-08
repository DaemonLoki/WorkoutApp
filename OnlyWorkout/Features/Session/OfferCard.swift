import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// The Step Up / Step Down question, shown after the last planned Set (or before the first Set after a Layoff).
/// A Step Up offers a heavier weight or one more rep; the prominent choice depends on the Exercise.
struct OfferCard: View {
    let offer: SessionOffer
    /// Bodyweight Exercises show one more rep as the prominent choice.
    let prefersReps: Bool
    let onAnswer: (_ accept: Bool, _ change: WeightSuggestion.Change?) -> Void

    var body: some View {
        let choices = offer.suggestion.choices(prefersReps: prefersReps)
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            Label {
                Text(offer.title).font(.headline)
            } icon: {
                Image(systemName: offer.symbol).foregroundStyle(.tint)
            }
            Text(offer.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let first = choices.first {
                Button {
                    onAnswer(true, first)
                } label: {
                    Text(offer.suggestion.acceptTitle(for: first)).frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .accessibilityIdentifier("acceptOfferButton")
            }
            // Side by side when both labels fit on one line, stacked otherwise.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: DesignTokens.Spacing.s) { secondaryButtons(choices) }
                VStack(spacing: DesignTokens.Spacing.s) { secondaryButtons(choices) }
            }
        }
        .controlSize(.large)
        .padding(DesignTokens.Spacing.m)
        .glassEffect(in: .rect(cornerRadius: DesignTokens.Radius.card))
    }

    /// The other choice of a Step Up, if any, and the decline.
    @ViewBuilder
    private func secondaryButtons(_ choices: [WeightSuggestion.Change]) -> some View {
        if choices.count > 1 {
            Button {
                onAnswer(true, choices[1])
            } label: {
                Text(offer.suggestion.acceptTitle(for: choices[1])).fixedSize().frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .accessibilityIdentifier("acceptOtherOfferButton")
        }
        Button {
            onAnswer(false, nil)
        } label: {
            Text(offer.declineTitle).fixedSize().frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .accessibilityIdentifier("declineOfferButton")
    }
}
