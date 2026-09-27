import OnlyWorkoutDesign
import SwiftUI

/// Rest countdown with what comes next underneath.
struct RestView: View {
    let interval: ClosedRange<Date>
    let next: String?
    let onExtend: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.l) {
            Text(.rest)
                .font(.title2.bold())
                .foregroundStyle(.secondary)

            RestRing(interval: interval)
                .frame(width: DesignTokens.Size.restRing, height: DesignTokens.Size.restRing)

            HStack(spacing: DesignTokens.Spacing.s) {
                Button(.extendRest, action: onExtend)
                Button(.skipRest, action: onSkip)
                    .accessibilityIdentifier("skipRestButton")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            if let next {
                VStack(spacing: DesignTokens.Spacing.xxs) {
                    Text(.nextLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(next)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}
