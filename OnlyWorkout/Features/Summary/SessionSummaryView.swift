import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// The end of every Session: the celebration, the numbers, and a card per progress moment.
struct SessionSummaryView: View {
    let summary: SessionSummary
    let onDone: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.l) {
                CelebrationMark()
                    .padding(.top, DesignTokens.Spacing.xl)

                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text(headline)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text(
                        .summaryStats(
                            String(localized: .setCount(summary.setCount)), summary.volume.kilograms, durationText)
                    )
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }

                ForEach(summary.events.enumerated(), id: \.offset) { index, event in
                    MotivationCard(event: event, sessionID: summary.sessionID, index: index)
                        .opacity(revealed ? 1 : 0)
                        .offset(y: revealed || reduceMotion ? 0 : DesignTokens.Spacing.m)
                        .animation(
                            (reduceMotion ? DesignTokens.Motion.reducedMotion : DesignTokens.Motion.card)
                                .delay(0.6 + Double(index) * DesignTokens.Motion.stagger),
                            value: revealed)
                }
            }
            .padding(DesignTokens.Spacing.m)
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onDone) {
                Text(.done).font(.headline).frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .padding(DesignTokens.Spacing.m)
            .accessibilityIdentifier("summaryDoneButton")
        }
        .onAppear { revealed = true }
    }

    private var headline: LocalizedStringResource {
        switch Motivation.variant(for: summary.sessionID, salt: 0, count: 3) {
        case 0: .summaryHeadline0(summary.workoutName)
        case 1: .summaryHeadline1(summary.workoutName)
        default: .summaryHeadline2(summary.workoutName)
        }
    }

    private var durationText: String {
        let allowed: Set<Duration.UnitsFormatStyle.Unit> = summary.duration < 60 ? [.seconds] : [.hours, .minutes]
        return Duration.seconds(summary.duration).formatted(.units(allowed: allowed, width: .abbreviated))
    }
}
