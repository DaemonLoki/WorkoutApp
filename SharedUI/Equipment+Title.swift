import OnlyWorkoutCore
import SwiftUI

extension Equipment {
    var title: LocalizedStringResource {
        switch self {
        case .barbell: .equipmentBarbell
        case .dumbbell: .equipmentDumbbell
        case .machine: .equipmentMachine
        case .cable: .equipmentCable
        case .bodyweight: .equipmentBodyweight
        case .kettlebell: .equipmentKettlebell
        }
    }
}
