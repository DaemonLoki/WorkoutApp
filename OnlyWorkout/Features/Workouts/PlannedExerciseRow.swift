import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// "Bench Press   3 × 10 · 60 kg", with a bracket for Supersets and a badge for a waiting Step Up.
struct PlannedExerciseRow: View {
    let planned: PlannedExercise
    var hasPendingSuggestion = false

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.s) {
            Capsule()
                .fill(planned.supersetID == nil ? AnyShapeStyle(.clear) : AnyShapeStyle(.tint))
                .frame(width: DesignTokens.Spacing.xxs)
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text(planned.exerciseName)
                Text(planned.target.summary)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            // Long Exercise names wrap at large Dynamic Type sizes instead of being cut off.
            .fixedSize(horizontal: false, vertical: true)
            Spacer()
            if planned.linkID != nil {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(Text(.linkedAccessibility))
            }
            if hasPendingSuggestion {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(.tint)
                    .accessibilityLabel(Text(.readyToStepUp))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(planned.supersetID == nil ? Text(verbatim: "") : Text(.superset))
    }
}
