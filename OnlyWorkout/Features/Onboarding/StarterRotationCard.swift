import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// One Starter Rotation to pick: its name, how many Workouts and how often it fits. The chosen one is outlined in
/// orange with a checkmark.
struct StarterRotationCard: View {
    let kind: StarterRotation.Kind
    let isSelected: Bool
    var isRecommended = false
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DesignTokens.Spacing.s) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Text(kind.title)
                            .font(.headline)
                        if isRecommended {
                            Text(.bestToStart)
                                .font(.caption.bold())
                                .foregroundStyle(.tint)
                                .padding(.horizontal, DesignTokens.Spacing.xs)
                                .padding(.vertical, 2)
                                .background(.tint.quaternary, in: .capsule)
                        }
                    }
                    Text(kind.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(DesignTokens.Spacing.m)
            .background(.background.secondary, in: .rect(cornerRadius: DesignTokens.Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                    .strokeBorder(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear), lineWidth: 2)
            }
            .contentShape(.rect(cornerRadius: DesignTokens.Radius.control))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
