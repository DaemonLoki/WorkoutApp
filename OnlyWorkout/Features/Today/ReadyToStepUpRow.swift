import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// A Step Up (or Step Down) that is waiting for an answer.
struct ReadyToStepUpRow: View {
    let suggestion: ProgressionSuggestion
    @Environment(AppModel.self) private var appModel
    @State private var acceptedCount = 0

    var body: some View {
        let planned = appModel.log.plannedExercise(id: suggestion.plannedExerciseID)
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(.exerciseInWorkout(planned?.exerciseName ?? "", planned?.workout?.name ?? ""))
                .font(.headline)
            Text(message(planned: planned))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            let offered = suggestion.suggestion
            let choices = offered.choices(prefersReps: planned?.exercise?.equipment.usesAddedWeight ?? false)
            // Side by side when they fit, stacked otherwise (large Dynamic Type).
            ViewThatFits(in: .horizontal) {
                HStack(spacing: DesignTokens.Spacing.xs) { buttons(for: choices, of: offered) }
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) { buttons(for: choices, of: offered) }
            }
        }
        .sensoryFeedback(.success, trigger: acceptedCount)
        .swipeActions {
            Button(.dismiss, systemImage: "xmark") { appModel.dismiss(suggestion) }
        }
    }

    /// The prominent choice first; a Step Up offers a heavier weight and one more rep.
    private func buttons(for choices: [WeightSuggestion.Change], of offered: WeightSuggestion) -> some View {
        ForEach(choices, id: \.self) { change in
            let button = Button {
                appModel.accept(suggestion, choosing: change)
                acceptedCount += 1
            } label: {
                Text(offered.acceptTitle(for: change))
            }
            if change == choices.first {
                button.buttonStyle(.glassProminent)
            } else {
                button.buttonStyle(.glass)
            }
        }
    }

    private func message(planned: PlannedExercise?) -> LocalizedStringResource {
        switch suggestion.reason {
        case .targetHit:
            .readyTargetHit(planned?.targetSets ?? 0, planned?.targetReps ?? 0, suggestion.fromWeight.kilograms)
        case .stall, .layoff:
            suggestion.suggestion.changes == [.reps]
                ? .readyStalledReps(suggestion.suggestion.fromReps) : .readyStalled(suggestion.fromWeight.kilograms)
        }
    }
}
