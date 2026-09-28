import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// Celebration and key numbers at the end of a Session.
struct WatchSummaryView: View {
    let summary: SessionSummary
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.s) {
                CelebrationMark(size: DesignTokens.Size.watchCelebrationMark)
                Text(summary.headline)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text(summary.statsLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                ForEach(summary.events.enumerated(), id: \.offset) { index, event in
                    Label {
                        Text(event.title(variant: summary.eventVariant(at: index)))
                            .font(.footnote)
                    } icon: {
                        Image(systemName: event.symbol).foregroundStyle(.tint)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button(.done, action: onDone)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, DesignTokens.Spacing.xs)
            }
        }
    }
}
