import OnlyWorkoutDesign
import OnlyWorkoutSync
import SwiftUI

/// "Already use OnlyWorkout?": Sign in with Apple restores everything through Cloud Sync; Start Fresh, with equal
/// standing, goes on without an account (README §7 Onboarding, App Review 5.1.1(v)).
struct RestorePage: View {
    let model: OnboardingModel
    let cloud: CloudSync
    @State private var isRestoring = false

    var body: some View {
        OnboardingPage(title: .restoreTitle, message: .restoreMessage) {
            Image(systemName: "arrow.clockwise.icloud")
                .font(.system(size: DesignTokens.Size.onboardingSymbol))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        } actions: {
            if isRestoring {
                ProgressView {
                    Text(.restoring)
                }
                .frame(minHeight: DesignTokens.Size.minimumTapTarget * 2)
            } else {
                CloudSignInButton(cloud: cloud, isSigningIn: $isRestoring) {
                    Task { await model.restored() }
                }
                .frame(height: DesignTokens.Size.minimumTapTarget + DesignTokens.Spacing.s)
                Button {
                    Task { await model.advance() }
                } label: {
                    Text(.startFresh)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .controlSize(.extraLarge)
                .accessibilityIdentifier("startFreshButton")
            }
            Text(.restoreFooter)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .animation(DesignTokens.Motion.reducedMotion, value: isRestoring)
    }
}
