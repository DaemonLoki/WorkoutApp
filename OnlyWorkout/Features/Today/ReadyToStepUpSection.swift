import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// Pending Step Ups and Step Downs, collapsed into one count until tapped open (README §7, Today).
struct ReadyToStepUpSection: View {
    let suggestions: [ProgressionSuggestion]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Collapsed on every launch.
    @State private var isExpanded = false

    var body: some View {
        Section {
            DisclosureGroup(
                isExpanded: $isExpanded.animation(
                    reduceMotion ? DesignTokens.Motion.reducedMotion : DesignTokens.Motion.disclosure)
            ) {
                ForEach(suggestions) { suggestion in
                    ReadyToStepUpRow(suggestion: suggestion)
                }
            } label: {
                indicator
            }
            .sensoryFeedback(.selection, trigger: isExpanded)
        }
    }

    private var indicator: some View {
        let stepUps = suggestions.count(where: { $0.kind == .stepUp })
        let stepDowns = suggestions.count - stepUps
        return Label {
            if stepUps > 0 {
                Text(.readyToStepUpCount(stepUps)).font(.headline)
                if stepDowns > 0 {
                    Text(.readyToStepDownCount(stepDowns)).foregroundStyle(.secondary)
                }
            } else {
                Text(.readyToStepDownCount(stepDowns)).font(.headline)
            }
        } icon: {
            Image(systemName: stepUps > 0 ? "arrow.up.circle.fill" : "arrow.down.circle")
                .foregroundStyle(stepUps > 0 ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .font(.title2)
        }
    }
}
