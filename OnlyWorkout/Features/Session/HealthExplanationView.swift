import OnlyWorkoutDesign
import SwiftUI

/// One screen before the Apple Health permission sheet, so the request makes sense (README §11).
struct HealthExplanationView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.l) {
            AppleHealthIcon(size: DesignTokens.Size.onboardingSymbol)
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(.healthExplanationTitle)
                    .font(.title2.bold())
                Text(.healthExplanationMessage)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            Button(action: onContinue) {
                Text(.continueLabel).font(.headline).frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
        }
        .padding(DesignTokens.Spacing.l)
        .presentationDetents([.medium])
        .interactiveDismissDisabled()
    }
}
