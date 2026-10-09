import OnlyWorkoutDesign
import SwiftUI

/// Tour page 4: the same Sets clicked through on Apple Watch, with heart rate, ending with every Set logged.
struct WatchDemo: View {
    let isActive: Bool
    @State private var demo = SetDemo()
    /// A plausible heart rate that climbs a little with every Set.
    private var heartRate: Int { 112 + demo.setNumber * 6 }

    var body: some View {
        // Laid out at the watch's size, then scaled up (to 1.5×) to fill the space above the caption.
        GeometryReader { proxy in
            let size = WatchFrame<EmptyView>.size
            let scale = min(proxy.size.width / size.width, proxy.size.height / size.height, 1.5)
            WatchFrame {
                Group {
                    if demo.isFinished {
                        VStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: DesignTokens.Size.watchCelebrationMark * 0.6))
                                .foregroundStyle(.tint)
                            Text(.allSetsDone)
                                .font(.headline)
                        }
                        .onTapGesture { demo.reset() }
                    } else {
                        WatchSetReplica(
                            exerciseName: "Bench Press", setNumber: demo.setNumber, totalSets: SetDemo.totalSets,
                            reps: SetDemo.reps, weight: SetDemo.weight, heartRate: heartRate, onDone: demo.tap)
                    }
                }
                .animation(DesignTokens.Motion.reducedMotion, value: demo.setNumber)
                .tapIndicatorOnDone(trigger: demo.autoTaps)
            }
            .scaleEffect(scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .dynamicTypeSize(.large)
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
    WatchDemo(isActive: true)
        .padding()
}
