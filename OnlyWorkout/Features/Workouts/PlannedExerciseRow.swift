import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// "Bench Press   3 × 10 · 60 kg", with a bracket for Supersets and a badge for a waiting Step Up.
struct PlannedExerciseRow: View {
    let summary: PlannedExerciseSummary
    var hasPendingSuggestion = false

    init(summary: PlannedExerciseSummary, hasPendingSuggestion: Bool = false) {
        self.summary = summary
        self.hasPendingSuggestion = hasPendingSuggestion
    }

    init(planned: PlannedExercise, hasPendingSuggestion: Bool = false) {
        self.init(summary: PlannedExerciseSummary(planned), hasPendingSuggestion: hasPendingSuggestion)
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.s) {
            Capsule()
                .fill(summary.isSuperset ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear))
                .frame(width: DesignTokens.Spacing.xxs)
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text(summary.name)
                Text(summary.showsWeight ? summary.target.summary : summary.target.setsAndReps)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            // Long Exercise names wrap at large Dynamic Type sizes instead of being cut off.
            .fixedSize(horizontal: false, vertical: true)
            Spacer()
            if summary.isLinked {
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
        .accessibilityHint(summary.isSuperset ? Text(.superset) : Text(verbatim: ""))
    }
}
