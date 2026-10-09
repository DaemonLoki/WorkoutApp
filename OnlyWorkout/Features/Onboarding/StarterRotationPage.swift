import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftData
import SwiftUI

/// "Pick your first Workouts": a Starter Rotation for the Equipment Access people have, previewed Exercise by
/// Exercise, or Build My Own in the Workout editor (README §7 Onboarding).
struct StarterRotationPage: View {
    @Bindable var model: OnboardingModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAdding = false

    var body: some View {
        OnboardingPage(title: .starterTitle, message: .starterMessage, centersContent: false) {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.l) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Picker(selection: $model.equipmentAccess) {
                        ForEach(EquipmentAccess.allCases) { access in
                            Text(access.shortTitle).tag(access)
                        }
                    } label: {
                        Text(.equipmentAccess)
                    }
                    .pickerStyle(.segmented)
                    Text(model.equipmentAccess.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .id(model.equipmentAccess)
                        .transition(.blurReplace)
                }

                VStack(spacing: DesignTokens.Spacing.s) {
                    ForEach(StarterRotation.Kind.allCases) { kind in
                        StarterRotationCard(
                            kind: kind, isSelected: model.rotationKind == kind, isRecommended: kind == .fullBody
                        ) {
                            withAnimation(DesignTokens.Motion.valueChange) { model.rotationKind = kind }
                        }
                    }
                }
                .sensoryFeedback(.selection, trigger: model.rotationKind)

                // A blur masks the moment both previews overlap while they cross-fade.
                preview
                    .id(model.rotation)
                    .transition(.blurReplace)

                Text(.starterHealthNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .animation(
                reduceMotion ? DesignTokens.Motion.reducedMotion : DesignTokens.Motion.disclosure, value: model.rotation
            )
        } actions: {
            OnboardingButton(title: .continueLabel, isWorking: isAdding) {
                isAdding = true
                Task {
                    await model.chooseStarterRotation()
                    isAdding = false
                }
            }
            .accessibilityIdentifier("chooseStarterButton")
            Button {
                Task { await model.buildOwnWorkout() }
            } label: {
                Text(.buildMyOwn)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: DesignTokens.Size.minimumTapTarget)
            }
            // Orange stays with the primary action.
            .tint(.primary)
            .accessibilityIdentifier("buildMyOwnButton")
        }
    }

    /// Every Workout of the chosen Starter Rotation with its Exercises and Targets, in Rotation order.
    private var preview: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.m) {
            ForEach(model.rotation.workouts, id: \.focus) { workout in
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(workout.focus.workoutName)
                        .font(.title3.bold())
                    ForEach(OnboardingModel.summary(of: workout)) { planned in
                        PlannedExerciseRow(summary: planned)
                    }
                }
                .cardBackground()
            }
        }
    }
}

#Preview {
    let container = SampleData.previewContainer()
    let appModel = AppModel(log: TrainingLog(context: container.mainContext))
    NavigationStack {
        StarterRotationPage(model: OnboardingModel(appModel: appModel))
    }
    .environment(appModel)
    .modelContainer(container)
}
