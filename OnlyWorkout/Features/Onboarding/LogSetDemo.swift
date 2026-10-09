import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// Tour page 2: the real Set view with Bench Press prefilled, clicked through Set by Set: tap Done (or wait a moment
/// and watch the fingertip) and the next Set is up, until every Set is logged. Finish, or leaving the page, starts over.
struct LogSetDemo: View {
    let isActive: Bool
    @State private var demo = SetDemo()
    private static let exerciseID = UUID()

    var body: some View {
        DemoScreen {
            Group {
                if demo.isFinished {
                    AllSetsDoneView { demo.reset() }
                } else {
                    let prompt = SessionEngine.SetPrompt(
                        exerciseID: Self.exerciseID, setNumber: demo.setNumber, totalSets: SetDemo.totalSets,
                        reps: SetDemo.reps, weight: SetDemo.weight)
                    SetView(
                        prompt: prompt, exerciseName: "Bench Press", isSuperset: false, afterRest: nil,
                        usesAddedWeight: false, weightStep: Equipment.barbell.defaultWeightStep, onSkipSet: {},
                        onSkipExercise: {}
                    ) { _, _ in
                        demo.tap()
                    }
                    // A new Set starts from its Target, as in a Session.
                    .id(prompt)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(DesignTokens.Motion.reducedMotion, value: demo.setNumber)
            .tapIndicatorOnDone(trigger: demo.autoTaps)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: demo.taps)
        .task(id: isActive) {
            guard isActive else {
                demo.reset()
                return
            }
            await demo.play()
        }
    }
}

#Preview {
    LogSetDemo(isActive: true)
        .padding()
}
