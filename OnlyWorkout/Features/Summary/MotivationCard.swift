import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// One progress moment, rendered from a handwritten template filled with real numbers.
struct MotivationCard: View {
    let event: MotivationEvent
    let sessionID: UUID
    let index: Int

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title).font(.headline)
                Text(message).font(.subheadline).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.tint)
        }
        .cardBackground()
    }

    private var variant: Int {
        Motivation.variant(for: sessionID, salt: index + 1, count: 2)
    }

    private var symbol: String {
        switch event {
        case .stepUp: "arrow.up.circle.fill"
        case .targetHit: "target"
        case .newBest: "star.fill"
        case .comeback: "hand.wave.fill"
        }
    }

    private var title: LocalizedStringResource {
        switch event {
        case .stepUp(let exercise, _, _, _, _): .eventStepUpTitle(exercise)
        case .targetHit(let exercise, _):
            variant == 0 ? .eventTargetHitTitle0(exercise) : .eventTargetHitTitle1(exercise)
        case .newBest(let exercise, _): .eventNewBestTitle(exercise)
        case .comeback: variant == 0 ? .eventComebackTitle0 : .eventComebackTitle1
        }
    }

    private var message: LocalizedStringResource {
        switch event {
        case .stepUp(_, let from, let to, let gain, let firstDate):
            if let gain, let firstDate, gain > to - from {
                .eventStepUpMessageSince(
                    from.kilograms, to.kilograms, gain.kilogramsChange,
                    firstDate.formatted(.dateTime.month(.wide)))
            } else {
                .eventStepUpMessage(from.kilograms, to.kilograms)
            }
        case .targetHit(_, let target):
            .eventTargetHitMessage(target.sets, target.reps, target.weight.kilograms)
        case .newBest(_, let set):
            .eventNewBestMessage(set.reps, set.weight.kilograms)
        case .comeback:
            .eventComebackMessage
        }
    }
}
