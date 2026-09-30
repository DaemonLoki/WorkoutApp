import Foundation
import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

extension SessionSummary {
    var headline: LocalizedStringResource {
        switch Motivation.variant(for: sessionID, salt: 0, count: 3) {
        case 0: .summaryHeadline0(workoutName)
        case 1: .summaryHeadline1(workoutName)
        default: .summaryHeadline2(workoutName)
        }
    }

    /// e.g. "3 sets · 1,260 kg moved · 42 min"
    var statsLine: LocalizedStringResource {
        let allowed: Set<Duration.UnitsFormatStyle.Unit> = duration < 60 ? [.seconds] : [.hours, .minutes]
        return .summaryStats(
            String(localized: .setCount(setCount)), volume.kilograms,
            Duration.seconds(duration).formatted(.units(allowed: allowed, width: .abbreviated)))
    }

    func eventVariant(at index: Int) -> Int {
        Motivation.variant(for: sessionID, salt: index + 1, count: 2)
    }
}
