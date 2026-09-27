import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// Target, Weight Step and Rest for one Planned Exercise.
struct PlannedExerciseEditorView: View {
    @Bindable var planned: PlannedExercise
    @Environment(\.dismiss) private var dismiss
    @FocusState private var weightIsFocused: Bool

    var body: some View {
        Form {
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
        .onChange(of: planned.target) { planned.updatedAt = .now }
        .onChange(of: planned.weightStep) { planned.updatedAt = .now }
        .onChange(of: planned.restSeconds) { planned.updatedAt = .now }
    }

    private var weightLabel: LocalizedStringResource {
        planned.exercise?.equipment.usesAddedWeight == true ? .addedWeightKg : .weightKg
    }
}
