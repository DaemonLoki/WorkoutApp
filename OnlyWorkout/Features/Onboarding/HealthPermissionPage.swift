import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftData
import SwiftUI

/// The Apple Health pre-permission page: what it adds, then exactly one Continue that opens Apple Health's sheet.
/// No close, back or "Not now": people decide in the sheet itself (HIG Privacy; App Review 5.1.1(iv)).
struct HealthPermissionPage: View {
    let model: OnboardingModel
    let appModel: AppModel
    @State private var isAsking = false

    var body: some View {
        OnboardingPage(title: .healthPageTitle, message: .healthPageMessage) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                AppleHealthIcon(size: DesignTokens.Size.onboardingSymbol)
                Text(.appleHealth)
                    .font(.footnote.bold())
                    .foregroundStyle(.secondary)
            }
            .accessibilityHidden(true)
        } actions: {
            OnboardingButton(title: .continueLabel, isWorking: isAsking) {
                isAsking = true
                Task {
                    await appModel.requestHealthAuthorization()
                    await model.advance()
                }
            }
            .accessibilityIdentifier("healthContinueButton")
        }
    }
}

#Preview {
    let container = SampleData.previewContainer()
    let appModel = AppModel(log: TrainingLog(context: container.mainContext))
    HealthPermissionPage(model: OnboardingModel(appModel: appModel), appModel: appModel)
}
