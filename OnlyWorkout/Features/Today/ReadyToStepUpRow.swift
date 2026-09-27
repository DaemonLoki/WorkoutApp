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
            Button {
                appModel.log.accept(suggestion)
                acceptedCount += 1
            } label: {
                Text(
                    suggestion.kind == .stepUp
                        ? .stepUpTo(suggestion.toWeight.kilograms) : .stepDownTo(suggestion.toWeight.kilograms))
            }
            .buttonStyle(.glassProminent)
        }
        .sensoryFeedback(.success, trigger: acceptedCount)
        .swipeActions {
            Button(.dismiss, systemImage: "xmark") { appModel.log.dismiss(suggestion) }
        }
    }

    private func message(planned: PlannedExercise?) -> LocalizedStringResource {
        switch suggestion.reason {
        case .targetHit:
            .readyTargetHit(planned?.targetSets ?? 0, planned?.targetReps ?? 0, suggestion.fromWeight.kilograms)
        case .stall, .layoff:
            .readyStalled(suggestion.fromWeight.kilograms)
        }
    }
}
