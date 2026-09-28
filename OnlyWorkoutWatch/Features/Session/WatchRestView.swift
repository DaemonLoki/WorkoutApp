import OnlyWorkoutDesign
import SwiftUI

/// Rest countdown with what comes next.
struct WatchRestView: View {
    let interval: ClosedRange<Date>
    let next: String?
    let onExtend: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xs) {
                RestRing(interval: interval, lineWidth: DesignTokens.Size.watchRestRingLineWidth)
                    .frame(width: DesignTokens.Size.watchRestRing, height: DesignTokens.Size.watchRestRing)
                if let next {
                    Text(next)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Button(.extendRest, action: onExtend)
                    Button(.skipRest, action: onSkip)
                }
                .controlSize(.small)
            }
        }
    }
}
