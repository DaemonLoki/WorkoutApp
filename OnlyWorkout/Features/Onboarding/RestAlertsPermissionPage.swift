import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftData
import SwiftUI

/// The Rest-alert pre-permission page: one sentence, then exactly one Continue that opens the notification alert.
struct RestAlertsPermissionPage: View {
    let model: OnboardingModel
    @State private var isAsking = false

    var body: some View {
        OnboardingPage(title: .restAlertsTitle, message: .restAlertsMessage) {
            Image(systemName: "bell.badge")
                .font(.system(size: DesignTokens.Size.onboardingSymbol))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        } actions: {
            OnboardingButton(title: .continueLabel, isWorking: isAsking) {
                isAsking = true
                Task {
                    await RestNotifier.requestPermission()
                    await model.advance()
                }
            }
            .accessibilityIdentifier("restAlertsContinueButton")
        }
    }
}

#Preview {
    let container = SampleData.previewContainer()
    let appModel = AppModel(log: TrainingLog(context: container.mainContext))
    RestAlertsPermissionPage(model: OnboardingModel(appModel: appModel))
}
