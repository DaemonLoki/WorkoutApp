import OnlyWorkoutDesign
import SwiftUI

/// A big number with − / + buttons; adjustable with VoiceOver swipes too.
struct ValueAdjuster: View {
    let title: LocalizedStringResource
    let valueText: String
    let value: Double
    let decrement: () -> Void
    let increment: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxs) {
            HStack(spacing: DesignTokens.Spacing.m) {
                Button(.decrease, systemImage: "minus", action: decrement)
                    .accessibilityHidden(true)
                BigNumberText(value, text: valueText)
                    .frame(maxWidth: .infinity)
                Button(.increase, systemImage: "plus", action: increment)
                    .accessibilityHidden(true)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .font(.title2.bold())

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(valueText)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: increment()
            case .decrement: decrement()
            @unknown default: break
            }
        }
    }
}
