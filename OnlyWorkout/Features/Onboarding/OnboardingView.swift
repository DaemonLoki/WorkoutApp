import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftData
import SwiftUI

/// First-launch onboarding (README §7 Onboarding): the Welcome Tour, then setup steps as a plain sequence. Setup
/// can't be swiped through, so a permission page can only be left through its one button.
struct OnboardingView: View {
    let appModel: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: OnboardingModel

    init(appModel: AppModel) {
        self.appModel = appModel
        _model = State(initialValue: OnboardingModel(appModel: appModel))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                step(model)
                    .id(model.step)
                    .transition(transition(movingForward: model.movesForward))
            }
            .animation(reduceMotion ? DesignTokens.Motion.reducedMotion : DesignTokens.Motion.step, value: model.step)
        }
        .task { model.checkPermissions() }
    }

    @ViewBuilder
    private func step(_ model: OnboardingModel) -> some View {
        switch model.step {
        case .tour:
            TourView(finishTitle: .continueLabel, leaveTitle: .skip) {
                Task { await model.advance() }
            }
        case .restore:
            if let cloud = appModel.cloud {
                RestorePage(model: model, cloud: cloud)
            }
        case .starterRotation: StarterRotationPage(model: model)
        case .startingWeights: StartingWeightsPage(model: model)
        case .health: HealthPermissionPage(model: model, appModel: appModel)
        case .restAlerts: RestAlertsPermissionPage(model: model)
        case .ready: ReadyPage(model: model, appModel: appModel)
        }
    }

    private func transition(movingForward: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .push(from: movingForward ? .trailing : .leading)
    }
}

#Preview {
    let container = SampleData.previewContainer()
    let appModel = AppModel(log: TrainingLog(context: container.mainContext))
    OnboardingView(appModel: appModel)
        .environment(appModel)
        .modelContainer(container)
}
