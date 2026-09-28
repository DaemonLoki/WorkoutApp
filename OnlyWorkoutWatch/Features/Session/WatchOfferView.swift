import OnlyWorkoutDesign
import OnlyWorkoutCore
import OnlyWorkoutStore
import SwiftUI

/// The Step Up / Step Down question on the wrist; Rest keeps counting at the top.
struct WatchOfferView: View {
    let offer: SessionOffer
    let rest: SessionEngine.Rest?
    let onAnswer: (_ accept: Bool) -> Void

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
                Button(offer.acceptTitle) { onAnswer(true) }
                    .buttonStyle(.borderedProminent)
                Button(offer.declineTitle) { onAnswer(false) }
            }
        }
    }
}
