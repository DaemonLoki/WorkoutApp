import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftData
import SwiftUI

/// Weights for the chosen Starter Rotation, each Exercise once. Empty starts at 0 kg; everything can change later.
struct StartingWeightsPage: View {
    @Bindable var model: OnboardingModel
    @FocusState private var focusedKey: String?
    @State private var isAdding = false
    /// Room for "102.5" at any text size.
    @ScaledMetric private var fieldWidth = 72.0

    var body: some View {
        List {
            Section {
                VStack(spacing: DesignTokens.Spacing.s) {
                    Text(.startingWeightsTitle)
                        .font(.largeTitle.bold())
                    Text(.startingWeightsMessage)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                .listRowBackground(Color.clear)
            }
            ForEach(model.weightedExercises, id: \.focus) { group in
                Section {
                    ForEach(group.exercises, id: \.catalogKey) { planned in
                        weightRow(planned)
                    }
                } header: {
                    Text(group.focus.workoutName)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaBar(edge: .bottom) {
            // While typing, the keyboard's Done takes over.
            if focusedKey == nil {
                continueButton
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(.back, systemImage: "chevron.backward") { model.goBackToStarterRotation() }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(.done) { focusedKey = nil }
            }
        }
    }

    private var continueButton: some View {
        OnboardingButton(title: .continueLabel, isWorking: isAdding) {
            isAdding = true
            model.addStarterRotation()
            Task {
                await model.advance()
                isAdding = false
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.l)
        .padding(.bottom, DesignTokens.Spacing.s)
        .frame(maxWidth: DesignTokens.Size.readableWidth)
        .accessibilityIdentifier("startingWeightsContinueButton")
    }

    private func weightRow(_ planned: StarterRotation.PlannedExercise) -> some View {
        let name = OnboardingModel.catalog[planned.catalogKey]?.name ?? planned.catalogKey
        return HStack(spacing: DesignTokens.Spacing.s) {
            VStack(alignment: .leading) {
                Text(verbatim: name)
                Text(Target(sets: planned.sets, reps: planned.reps, weight: 0).setsAndReps)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .layoutPriority(1)
            HStack(spacing: DesignTokens.Spacing.xxs) {
                TextField(value: $model.weights[planned.catalogKey], format: .number, prompt: Text(verbatim: "0")) {
                    Text(verbatim: name)
                }
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .focused($focusedKey, equals: planned.catalogKey)
                .frame(width: fieldWidth)
                .frame(minHeight: DesignTokens.Size.minimumTapTarget)
                Text(.kg)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let container = SampleData.previewContainer()
    let appModel = AppModel(log: TrainingLog(context: container.mainContext))
    NavigationStack {
        StartingWeightsPage(model: OnboardingModel(appModel: appModel))
    }
    .environment(appModel)
    .modelContainer(container)
}
