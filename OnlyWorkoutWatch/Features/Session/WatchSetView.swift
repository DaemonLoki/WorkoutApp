import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// One Set on the wrist: turn the Digital Crown to change reps, tap Done.
struct WatchSetView: View {
    let prompt: SessionEngine.SetPrompt
    let exerciseName: String
    let isSuperset: Bool
    let weightStep: Double
    let heartRate: Double?
    let onSkipSet: () -> Void
    let onSkipExercise: () -> Void
    let onDone: (_ reps: Int, _ weight: Double) -> Void

    @State private var crownReps: Double
    @State private var weight: Double
    @State private var editsWeight = false
    @State private var choosesSkip = false

    init(
        prompt: SessionEngine.SetPrompt, exerciseName: String, isSuperset: Bool, weightStep: Double, heartRate: Double?,
        onSkipSet: @escaping () -> Void, onSkipExercise: @escaping () -> Void,
        onDone: @escaping (_ reps: Int, _ weight: Double) -> Void
    ) {
        self.prompt = prompt
        self.exerciseName = exerciseName
        self.isSuperset = isSuperset
        self.weightStep = weightStep
        self.heartRate = heartRate
        self.onSkipSet = onSkipSet
        self.onSkipExercise = onSkipExercise
        self.onDone = onDone
        _crownReps = State(initialValue: Double(prompt.reps))
        _weight = State(initialValue: prompt.weight)
    }

    private var reps: Int { Int(crownReps.rounded()) }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxs) {
            Text(exerciseName)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(prompt.isExtra ? .extraSet : .setProgress(prompt.setNumber, prompt.totalSets))
                .font(.footnote)
                .foregroundStyle(isSuperset ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))

            BigNumberText(Double(reps), text: "\(reps)", baseSize: 48)
                .focusable()
                .digitalCrownRotation(
                    $crownReps, from: 0, through: 100, by: 1, sensitivity: .low, isContinuous: false,
                    isHapticFeedbackEnabled: true)
                .accessibilityLabel(Text(.reps))
                .accessibilityValue(Text(reps, format: .number))

            Button {
                editsWeight = true
            } label: {
                Text(weight.kilograms).monospacedDigit()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityHint(Text(.changeWeight))

            Button(.done) { onDone(reps, weight) }
                .buttonStyle(.borderedProminent)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(.skip, systemImage: "forward") { choosesSkip = true }
                    .confirmationDialog(Text(.skip), isPresented: $choosesSkip) {
                        Button(.skipSet, action: onSkipSet)
                        Button(.skipExerciseNamed(exerciseName), action: onSkipExercise)
                    }
            }
            if let heartRate {
                ToolbarItem(placement: .topBarTrailing) {
                    Label {
                        Text(heartRate, format: .number.precision(.fractionLength(0)))
                    } icon: {
                        Image(systemName: "heart.fill").foregroundStyle(.red)
                    }
                    .font(.footnote)
                    .monospacedDigit()
                    .accessibilityLabel(Text(.heartRateValue(Int(heartRate))))
                }
            }
        }
        .sheet(isPresented: $editsWeight) {
            WatchWeightEditor(weight: $weight, step: weightStep)
        }
    }
}
