import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftData
import SwiftUI

/// The end of onboarding: the celebration mark and the Workout that's Next Up, then Today (README §7 Onboarding).
struct ReadyPage: View {
    let model: OnboardingModel
    let appModel: AppModel

    var body: some View {
        let workouts = model.workouts
        let nextUp = appModel.log.nextUp(in: workouts)
        let later = workouts.filter { $0.id != nextUp?.id }.map(\.name)
        OnboardingPage(
            title: model.hasRestored ? .readyRestoredTitle : .readyTitle,
            message: model.hasRestored ? .readyRestoredMessage : .readyMessage
        ) {
            CelebrationMark()
        } content: {
            if let nextUp {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(.nextUp)
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, DesignTokens.Spacing.m)
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
                        Text(nextUp.name)
                            .font(.title2.bold())
                        ForEach(nextUp.orderedPlannedExercises) { planned in
                            PlannedExerciseRow(planned: planned)
                        }
                        if !later.isEmpty {
                            Text(.readyThen(later.formatted(.list(type: .and))))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.top, DesignTokens.Spacing.xxs)
                        }
                    }
                    .cardBackground()
                }
            }
        } actions: {
            OnboardingButton(title: .letsGo) { model.finish() }
                .accessibilityIdentifier("letsGoButton")
        }
    }
}

#Preview {
    let container = SampleData.previewContainer()
    let appModel = AppModel(log: TrainingLog(context: container.mainContext))
    ReadyPage(model: OnboardingModel(appModel: appModel), appModel: appModel)
        .modelContainer(container)
}
