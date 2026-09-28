import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// One progress moment on the Summary.
struct MotivationCard: View {
    let event: MotivationEvent
    let variant: Int

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(event.title(variant: variant)).font(.headline)
                Text(event.message).font(.subheadline).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: event.symbol)
                .font(.title2)
                .foregroundStyle(.tint)
        }
        .cardBackground()
    }
}
