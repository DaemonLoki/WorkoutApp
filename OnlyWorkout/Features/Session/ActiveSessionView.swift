import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// The full-screen Session: one Set at a time, Rest in between, Summary at the end.
/// Works the same whether the Session runs here or on the Watch.
struct ActiveSessionView: View {
    let session: any SessionDriver
    @Environment(AppModel.self) private var appModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsOverview = false
    @State private var confirmsEnd = false

    var body: some View {
        NavigationStack {
            if let summary = session.summary {
                SessionSummaryView(summary: summary) { appModel.closeSession() }
            } else if session.isWaitingForWatch {
                ProgressView {
                    Text(.connectingToWatch)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(.close, systemImage: "xmark") { appModel.closeSession() }
                    }
                }
            } else {
                sessionContent
            }
        }
        .interactiveDismissDisabled()
    }

    private var sessionContent: some View {
        Group {
            if let rest = session.engine.rest {
                RestView(
                    interval: rest.startedAt...rest.endsAt, next: session.nextSetDescription,
                    onExtend: session.extendRest, onSkip: session.finishRest)
            } else if let prompt = session.engine.currentSet, let exercise = session.exercise(id: prompt.exerciseID) {
                SetView(
                    prompt: prompt, exerciseName: exercise.name, isSuperset: exercise.supersetID != nil,
                    usesAddedWeight: session.usesAddedWeight(for: exercise.id),
                    weightStep: session.weightStep(for: exercise.id),
                    onSkipSet: { session.skipSet(of: exercise.id) },
                    onSkipExercise: { session.skip(exercise.id) }
                ) { reps, weight in
                    session.completeSet(reps: reps, weight: weight)
                }
                .id(prompt)
            } else {
                AllSetsDoneView(onFinish: session.finish)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignTokens.Spacing.m)
        .safeAreaInset(edge: .bottom) {
            if let offer = session.offer {
                OfferCard(offer: offer) { accept in
                    session.answer(offer, accept: accept)
                }
                .padding(DesignTokens.Spacing.m)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? DesignTokens.Motion.reducedMotion : DesignTokens.Motion.card, value: session.offer)
        .animation(DesignTokens.Motion.reducedMotion, value: session.engine.rest == nil)
        .sensoryFeedback(.impact(weight: .light), trigger: session.loggedSetCount)
        .sensoryFeedback(.success, trigger: session.restEndCount)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(.endSession, systemImage: "xmark") {
                    if session.hasRemainingSets { confirmsEnd = true } else { session.finish() }
                }
                .confirmationDialog(Text(.endSessionEarlyTitle), isPresented: $confirmsEnd, titleVisibility: .visible) {
                    Button(.endSession, role: .destructive, action: session.finish)
                } message: {
                    Text(.endSessionEarlyMessage)
                }
            }
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(session.workoutName).font(.headline)
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Text(session.startedAt, style: .timer)
                        if let heartRate = session.heartRate {
                            Label {
                                Text(heartRate, format: .number.precision(.fractionLength(0)))
                            } icon: {
                                Image(systemName: "heart.fill")
                            }
                            .accessibilityLabel(Text(.heartRateValue(Int(heartRate))))
                        }
                    }
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
            SessionOverviewSheet(session: session)
        }
    }
}
