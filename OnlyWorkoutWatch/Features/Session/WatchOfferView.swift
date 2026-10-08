import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// The Step Up / Step Down question on the wrist; Rest keeps counting at the top.
struct WatchOfferView: View {
    let offer: SessionOffer
    let rest: SessionEngine.Rest?
    /// Bodyweight Exercises show one more rep as the prominent choice.
    let prefersReps: Bool
    let onAnswer: (_ accept: Bool, _ change: WeightSuggestion.Change?) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                if let rest {
                    Text(timerInterval: rest.startedAt...rest.endsAt, countsDown: true)
                        .font(.footnote.bold())
                        .monospacedDigit()
                        .foregroundStyle(.tint)
                }
                Label {
                    Text(offer.title).font(.headline)
                } icon: {
                    Image(systemName: offer.symbol).foregroundStyle(.tint)
                }
                Text(offer.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                let choices = offer.suggestion.choices(prefersReps: prefersReps)
                if let first = choices.first {
                    Button(offer.suggestion.acceptTitle(for: first)) { onAnswer(true, first) }
                        .buttonStyle(.borderedProminent)
                }
                ForEach(choices.dropFirst(), id: \.self) { change in
                    Button(offer.suggestion.acceptTitle(for: change)) { onAnswer(true, change) }
                }
                Button(offer.declineTitle) { onAnswer(false, nil) }
            }
        }
    }
}
