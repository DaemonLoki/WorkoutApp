import OnlyWorkoutDesign
import SwiftUI

/// The full-width orange button that moves onboarding on; shows a spinner while its work runs.
struct OnboardingButton: View {
    let title: LocalizedStringResource
    var isWorking = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isWorking ? 0 : 1)
                if isWorking { ProgressView() }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.extraLarge)
        .disabled(isWorking)
    }
}
