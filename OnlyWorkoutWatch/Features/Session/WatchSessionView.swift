import OnlyWorkoutConnectivity
import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// A running Session on the wrist. Swipe left for the overview.
struct WatchSessionView: View {
    let runner: SessionRunner
    @Environment(WatchModel.self) private var model
    @State private var page = Page.current

    enum Page: Hashable {
        case current, overview
    }

    var body: some View {
        if let summary = runner.summary {
            WatchSummaryView(summary: summary) { model.closeSession() }
        } else {
            TabView(selection: $page) {
                // The navigation container lets the Set screen show its toolbar (skip, heart rate).
                NavigationStack { current }.tag(Page.current)
                WatchOverviewView(runner: runner) {
                    model.finish()
                }
                .tag(Page.overview)
            }
            .tabViewStyle(.page)
            .sensoryFeedback(.impact(weight: .light), trigger: runner.loggedSetCount)
            .sensoryFeedback(.success, trigger: runner.restEndCount)
        }
    }

    @ViewBuilder
    private var current: some View {
        if let offer = runner.offer {
            WatchOfferView(
                offer: offer, rest: runner.engine.rest, prefersReps: runner.usesAddedWeight(for: offer.exerciseID)
            ) { accept, change in
                runner.answer(offer, accept: accept, choosing: change)
            }
        } else if let rest = runner.engine.rest {
            WatchRestView(
                interval: rest.startedAt...rest.endsAt, next: nextDescription,
                onExtend: runner.extendRest, onSkip: runner.finishRest)
        } else if let prompt = runner.engine.currentSet, let exercise = runner.exercise(id: prompt.exerciseID) {
            WatchSetView(
                prompt: prompt, exerciseName: exercise.name, isSuperset: exercise.supersetID != nil,
                afterRest: afterRestDescription, weightStep: runner.weightStep(for: exercise.id),
                heartRate: model.recorder.heartRate,
                onSkipSet: { runner.skipSet(of: exercise.id) },
                onSkipExercise: { runner.skip(exercise.id) }
            ) { reps, weight in
                runner.completeSet(reps: reps, weight: weight)
            }
            .id(prompt)
        } else {
            VStack(spacing: DesignTokens.Spacing.s) {
                Text(.allSetsDone).font(.headline)
                Button(.finishSession) { model.finish() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var nextDescription: String? {
        guard let prompt = runner.engine.currentSet, let exercise = runner.exercise(id: prompt.exerciseID) else {
            return nil
        }
        return String(localized: .watchNextSet(exercise.name, prompt.reps, prompt.weight.kilograms))
    }

    /// During the last Set of a Superset pair: what follows the Rest it starts.
    private var afterRestDescription: String? {
        guard let prompt = runner.engine.setAfterRest, let exercise = runner.exercise(id: prompt.exerciseID) else {
            return nil
        }
        return String(localized: .watchAfterRest(exercise.name, prompt.reps, prompt.weight.kilograms))
    }
}
