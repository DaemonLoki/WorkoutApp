import OnlyWorkoutCore
import SwiftUI

extension EquipmentAccess {
    /// Short, for a segmented picker.
    var shortTitle: LocalizedStringResource {
        switch self {
        case .fullGym: .equipmentAccessGymShort
        case .dumbbellsAndBench: .equipmentAccessDumbbellsShort
        case .bodyweightOnly: .equipmentAccessBodyweightShort
        }
    }

    /// What it means in one sentence, including what it assumes.
    var detail: LocalizedStringResource {
        switch self {
        case .fullGym: .equipmentAccessGymDetail
        case .dumbbellsAndBench: .equipmentAccessDumbbellsDetail
        case .bodyweightOnly: .equipmentAccessBodyweightDetail
        }
    }

    /// Stored device-locally (`AppModel.equipmentAccessKey`); a gym until someone picks otherwise.
    static var stored: EquipmentAccess {
        UserDefaults.standard.string(forKey: AppModel.equipmentAccessKey).flatMap(EquipmentAccess.init) ?? .fullGym
    }
}
