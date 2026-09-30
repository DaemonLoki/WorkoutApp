import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// Target, Weight Step and Rest for one Planned Exercise.
struct PlannedExerciseEditorView: View {
    @Bindable var planned: PlannedExercise
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var weightIsFocused: Bool

    var body: some View {
        Form {
            if planned.linkID != nil {
                Section {
                    Label(.linkedWith(linkedWorkoutNames), systemImage: "link")
                    Button(.unlink, role: .destructive) { appModel.log.unlink(planned) }
                } footer: {
                    Text(.linkedFooter)
                }
            }
            Section {
                Stepper(value: $planned.targetSets, in: PlanDefaults.setsRange) {
                    LabeledContent {
                        Text(planned.targetSets, format: .number)
                    } label: {
                        Text(.sets)
                    }
                }
                Stepper(value: $planned.targetReps, in: PlanDefaults.repsRange) {
                    LabeledContent {
                        Text(planned.targetReps, format: .number)
                    } label: {
                        Text(.repsPerSet)
                    }
                }
                WeightField(title: weightLabel, weight: $planned.weight, isFocused: $weightIsFocused)
            } header: {
                Text(.target)
            } footer: {
                Text(.targetFooter(planned.targetSets, planned.targetReps))
            }

            Section {
                Picker(selection: $planned.weightStep) {
                    ForEach(PlanDefaults.weightSteps, id: \.self) { step in
                        Text(step.kilograms).tag(step)
                    }
                } label: {
                    Text(.weightStep)
                }
                Picker(selection: $planned.restSeconds) {
                    ForEach(
                        Array(
                            stride(
                                from: PlanDefaults.restRange.lowerBound, through: PlanDefaults.restRange.upperBound,
                                by: PlanDefaults.restStep)), id: \.self
                    ) { seconds in
                        Text(Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond))).tag(seconds)
                    }
                } label: {
                    Text(.rest)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(planned.exerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(.done) {
                    weightIsFocused = false
                    dismiss()
                }
                .accessibilityIdentifier("doneEditingButton")
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(.done) { weightIsFocused = false }
                    .accessibilityIdentifier("keyboardDoneButton")
            }
        }
        .onChange(of: planned.target, settingsChanged)
        .onChange(of: planned.weightStep, settingsChanged)
        .onChange(of: planned.restSeconds, settingsChanged)
    }

    /// Stamps the change and keeps Linked Planned Exercises in step.
    private func settingsChanged() {
        planned.updatedAt = .now
        appModel.log.propagateSettings(from: planned)
    }

    /// e.g. "Full Body and Upper Body"
    private var linkedWorkoutNames: String {
        appModel.log.linkGroup(of: planned)
            .filter { $0 !== planned }
            .compactMap { $0.workout?.name }
            .formatted(.list(type: .and))
    }

    private var weightLabel: LocalizedStringResource {
        planned.exercise?.equipment.usesAddedWeight == true ? .addedWeightKg : .weightKg
    }
}
