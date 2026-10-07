import OnlyWorkoutCore
import SwiftUI

/// Toolbar menu that narrows a list to one Muscle Group; the icon fills while a filter is set.
struct MuscleGroupFilter: View {
    @Binding var selection: MuscleGroup?

    var body: some View {
        Menu {
            Picker(selection: $selection) {
                Text(.allMuscleGroups).tag(MuscleGroup?.none)
                ForEach(MuscleGroup.allCases) { Text($0.title).tag(MuscleGroup?.some($0)) }
            } label: {
                Text(.muscleGroup)
            }
        } label: {
            Label(
                .muscleGroup,
                systemImage: selection == nil
                    ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
    }
}
