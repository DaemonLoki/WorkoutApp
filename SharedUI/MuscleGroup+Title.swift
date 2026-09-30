import OnlyWorkoutCore
import SwiftUI

extension MuscleGroup {
    var title: LocalizedStringResource {
        switch self {
        case .chest: .muscleChest
        case .lats: .muscleLats
        case .upperBack: .muscleUpperBack
        case .lowerBack: .muscleLowerBack
        case .traps: .muscleTraps
        case .shoulders: .muscleShoulders
        case .biceps: .muscleBiceps
        case .triceps: .muscleTriceps
        case .forearms: .muscleForearms
        case .abs: .muscleAbs
        case .obliques: .muscleObliques
        case .glutes: .muscleGlutes
        case .quads: .muscleQuads
        case .hamstrings: .muscleHamstrings
        case .adductors: .muscleAdductors
        case .calves: .muscleCalves
        }
    }
}

extension [MuscleGroup] {
    /// e.g. "Chest, Triceps"
    var joinedTitles: String {
        map { String(localized: $0.title) }.formatted(.list(type: .and, width: .narrow))
    }
}
