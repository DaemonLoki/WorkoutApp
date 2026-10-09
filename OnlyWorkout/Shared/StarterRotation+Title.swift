import OnlyWorkoutCore
import SwiftUI

extension StarterRotation.Kind {
    var title: LocalizedStringResource {
        switch self {
        case .fullBody: .starterFullBodyTitle
        case .upperLower: .starterUpperLowerTitle
        case .pushPullLegs: .starterPushPullLegsTitle
        }
    }

    /// How many Workouts, and how often it fits (docs/research/training-templates.md §4).
    var detail: LocalizedStringResource {
        switch self {
        case .fullBody: .starterFullBodyDetail
        case .upperLower: .starterUpperLowerDetail
        case .pushPullLegs: .starterPushPullLegsDetail
        }
    }
}
