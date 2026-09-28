import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// The Step Up / Step Down question, shown during Rest (or before the first Set after a Layoff).
struct OfferCard: View {
    let offer: SessionOffer
    let onAnswer: (_ accept: Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            Label {
                Text(offer.title).font(.headline)
            } icon: {
                Image(systemName: offer.symbol).foregroundStyle(.tint)
            }
            Text(offer.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: DesignTokens.Spacing.s) {
                Button {
                    onAnswer(true)
                } label: {
                    Text(offer.acceptTitle).frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .accessibilityIdentifier("acceptOfferButton")
                Button {
                    onAnswer(false)
                } label: {
                    Text(offer.declineTitle).frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .accessibilityIdentifier("declineOfferButton")
            }
            .controlSize(.large)
        }
        .padding(DesignTokens.Spacing.m)
        .glassEffect(in: .rect(cornerRadius: DesignTokens.Radius.card))
    }
}
