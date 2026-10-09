import OnlyWorkoutCore
import SwiftUI

extension Focus {
    /// The name a Workout of this Focus gets when it's added for someone, e.g. "Push Day".
    var workoutName: LocalizedStringResource {
        switch self {
        case .push: .focusPushWorkoutName
        case .pull: .focusPullWorkoutName
        case .legs: .focusLegsWorkoutName
        case .upperBody: .focusUpperBodyWorkoutName
        case .lowerBody: .focusLowerBodyWorkoutName
        case .fullBody: .focusFullBodyWorkoutName
        case .arms: .focusArmsWorkoutName
        case .core: .focusCoreWorkoutName
        }
    }
}
