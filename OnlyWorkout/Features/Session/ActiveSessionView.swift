import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// The full-screen Session: one Set at a time, Rest in between, Summary at the end.
struct ActiveSessionView: View {
    let controller: SessionController
    @Environment(AppModel.self) private var appModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsOverview = false
    @State private var confirmsEnd = false

    var body: some View {
        NavigationStack {
            if let summary = controller.summary {
                SessionSummaryView(summary: summary) { appModel.closeSession() }
            } else {
                sessionContent
            }
        }
        .interactiveDismissDisabled()
    }

    private var sessionContent: some View {
        Group {
            if let rest = controller.engine.rest {
                RestView(
                    interval: rest.startedAt...rest.endsAt, next: controller.nextSetDescription,
                    onExtend: controller.extendRest, onSkip: controller.finishRest)
            } else if let prompt = controller.engine.currentSet,
                let exercise = controller.exercise(id: prompt.exerciseID)
            {
                SetView(
                    prompt: prompt, exerciseName: exercise.name, isSuperset: exercise.supersetID != nil,
                    usesAddedWeight: controller.plannedExercise(for: exercise.id)?.exercise?.equipment.usesAddedWeight
                        ?? false,
                    weightStep: controller.weightStep(for: exercise.id)
                ) { reps, weight in
                    controller.completeSet(reps: reps, weight: weight)
                }
                .id(prompt)
            } else {
                AllSetsDoneView(onFinish: controller.finish)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignTokens.Spacing.m)
        .safeAreaInset(edge: .bottom) {
            if let offer = controller.offer {
                OfferCard(offer: offer) { accept in
                    controller.answer(offer, accept: accept)
                }
                .padding(DesignTokens.Spacing.m)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? DesignTokens.Motion.reducedMotion : DesignTokens.Motion.card, value: controller.offer)
        .animation(DesignTokens.Motion.reducedMotion, value: controller.engine.rest == nil)
        .sensoryFeedback(.impact(weight: .light), trigger: controller.loggedSetCount)
        .sensoryFeedback(.success, trigger: controller.restEndCount)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(.endSession, systemImage: "xmark") {
                    if controller.hasRemainingSets { confirmsEnd = true } else { controller.finish() }
                }
                .confirmationDialog(Text(.endSessionEarlyTitle), isPresented: $confirmsEnd, titleVisibility: .visible) {
                    Button(.endSession, role: .destructive, action: controller.finish)
                } message: {
                    Text(.endSessionEarlyMessage)
                }
            }
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(controller.session.workoutName).font(.headline)
                    Text(controller.session.startedAt, style: .timer)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(.sessionOverview, systemImage: "list.bullet") { showsOverview = true }
            }
        }
        .sheet(isPresented: $showsOverview) {
            SessionOverviewSheet(controller: controller)
        }
    }
}
