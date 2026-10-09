import SwiftUI

/// The pages of the Welcome Tour: a welcome, then what makes OnlyWorkout different (README §7 Onboarding).
enum TourPage: Int, CaseIterable, Identifiable {
    case welcome, plan, logSet, stepUp, watch, sync

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .welcome: .tourWelcomeTitle
        case .plan: .tourPlanTitle
        case .logSet: .tourLogSetTitle
        case .stepUp: .tourStepUpTitle
        case .watch: .tourWatchTitle
        case .sync: .tourSyncTitle
        }
    }

    var message: LocalizedStringResource {
        switch self {
        case .welcome: .tourWelcomeMessage
        case .plan: .tourPlanMessage
        case .logSet: .tourLogSetMessage
        case .stepUp: .tourStepUpMessage
        case .watch: .tourWatchMessage
        case .sync: .tourSyncMessage
        }
    }

    var next: TourPage? {
        TourPage(rawValue: rawValue + 1)
    }
}
