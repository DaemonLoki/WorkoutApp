import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// One Set: target reps and weight prefilled, adjustable, confirmed with one tap on Done.
struct SetView: View {
    let prompt: SessionEngine.SetPrompt
    let exerciseName: String
    let isSuperset: Bool
    let usesAddedWeight: Bool
    let weightStep: Double
    let onSkipSet: () -> Void
    let onSkipExercise: () -> Void
    let onDone: (_ reps: Int, _ weight: Double) -> Void

    @State private var reps: Int
    @State private var weight: Double

    init(
        prompt: SessionEngine.SetPrompt, exerciseName: String, isSuperset: Bool, usesAddedWeight: Bool,
        weightStep: Double, onSkipSet: @escaping () -> Void, onSkipExercise: @escaping () -> Void,
        onDone: @escaping (_ reps: Int, _ weight: Double) -> Void
    ) {
        self.prompt = prompt
        self.exerciseName = exerciseName
        self.isSuperset = isSuperset
        self.usesAddedWeight = usesAddedWeight
        self.weightStep = weightStep
        self.onSkipSet = onSkipSet
        self.onSkipExercise = onSkipExercise
        self.onDone = onDone
        _reps = State(initialValue: prompt.reps)
        _weight = State(initialValue: prompt.weight)
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.l) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(exerciseName)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                HStack(spacing: DesignTokens.Spacing.xs) {
                    if isSuperset {
                        Text(.superset).foregroundStyle(.tint)
                    }
                    Text(prompt.isExtra ? .extraSet : .setProgress(prompt.setNumber, prompt.totalSets))
                        .foregroundStyle(.secondary)
                }
                .font(.headline)
            }

            Spacer(minLength: 0)

            ValueAdjuster(
                title: .reps, valueText: "\(reps)", value: Double(reps),
                decrement: { reps = max(0, reps - 1) }, increment: { reps += 1 }
            )
            ValueAdjuster(
                title: usesAddedWeight ? .addedWeightKg : .weightKg, valueText: weight.weightNumber, value: weight,
                decrement: { weight = max(0, weight - weightStep) }, increment: { weight += weightStep }
            )

            Spacer(minLength: 0)

            Button {
                onDone(reps, weight)
            } label: {
                Text(.done)
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .accessibilityIdentifier("doneButton")

            Menu {
                Button(.skipSet, systemImage: "forward", action: onSkipSet)
                Button(.skipExerciseNamed(exerciseName), systemImage: "forward.end", action: onSkipExercise)
            } label: {
                Text(.skip)
                    .frame(minWidth: DesignTokens.Size.minimumTapTarget, minHeight: DesignTokens.Size.minimumTapTarget)
            }
            .accessibilityIdentifier("skipMenu")
        }
    }
}
