import Foundation
import Observation
import OnlyWorkoutDesign

/// Three Sets of Bench Press clicked through one tap at a time, for the Welcome Tour's Set demos on iPhone and
/// Apple Watch. After a short idle it taps Done by itself; once someone taps, they drive it.
@Observable
final class SetDemo {
    static let totalSets = 3
    static let reps = 8
    static let weight = 60.0

    /// The Set on screen, 1-based; past `totalSets` every Set is logged.
    private(set) var setNumber = 1
    /// Taps the demo made by itself, which show the fingertip (and play no haptic).
    private(set) var autoTaps = 0
    /// Taps people made, which play the Done haptic.
    private(set) var taps = 0

    var isFinished: Bool { setNumber > Self.totalSets }

    func tap() {
        taps += 1
        logSet()
    }

    /// Starts over, e.g. when the page is left or Finish is tapped.
    func reset() {
        setNumber = 1
        taps = 0
    }

    /// Clicks through the remaining Sets while nobody taps; ends when every Set is logged or the task is cancelled.
    func play() async {
        try? await Task.sleep(for: .seconds(DesignTokens.Motion.demoIdle))
        while !Task.isCancelled, !isFinished, taps == 0 {
            autoTaps += 1
            try? await Task.sleep(for: .seconds(DesignTokens.Motion.demoTapLanding))
            guard !Task.isCancelled, taps == 0 else { return }
            logSet()
            try? await Task.sleep(for: .seconds(DesignTokens.Motion.demoSetInterval))
        }
    }

    private func logSet() {
        guard !isFinished else { return }
        setNumber += 1
    }
}
