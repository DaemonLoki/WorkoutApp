import OnlyWorkoutCore
import SwiftUI

extension StatsRange {
    var title: LocalizedStringResource {
        switch self {
        case .fourWeeks: .range4W
        case .threeMonths: .range3M
        case .sixMonths: .range6M
        case .oneYear: .range1Y
        case .all: .rangeAll
        }
    }
}
