import OnlyWorkoutDesign
import SwiftUI

/// Shown for the few seconds it takes the Watch to pick up a Session.
struct StartingOnWatchView: View {
    let onStartOnPhone: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.m) {
            Image(systemName: "applewatch.radiowaves.left.and.right")
                .font(.largeTitle)
                .foregroundStyle(.tint)
                .symbolEffect(.pulse)
            Text(.startingOnWatch)
                .font(.headline)
            Button(.startOnIPhoneInstead, action: onStartOnPhone)
                .buttonStyle(.bordered)
        }
        .padding(DesignTokens.Spacing.l)
        .presentationDetents([.height(220)])
        .interactiveDismissDisabled()
    }
}
