import OnlyWorkoutDesign
import SwiftUI

/// Adjusts weight by the Weight Step with the Digital Crown or − / +.
struct WatchWeightEditor: View {
    @Binding var weight: Double
    let step: Double
    @State private var crownSteps: Double = 0
    @State private var baseWeight: Double = 0

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.s) {
            Text(.weightKg).font(.footnote).foregroundStyle(.secondary)
            HStack {
                Button(.decrease, systemImage: "minus") { crownSteps -= 1 }
                BigNumberText(weight, text: weight.weightNumber, baseSize: 36)
                    .focusable()
                    .digitalCrownRotation(
                        $crownSteps, from: -200, through: 200, by: 1, sensitivity: .low, isContinuous: false,
                        isHapticFeedbackEnabled: true)
                Button(.increase, systemImage: "plus") { crownSteps += 1 }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
        }
        .onAppear { baseWeight = weight }
        .onChange(of: crownSteps) { _, steps in
            weight = max(0, baseWeight + steps.rounded() * step)
        }
    }
}
