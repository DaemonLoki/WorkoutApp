import OnlyWorkoutCore
import SwiftUI

/// Picks which of Strava's exercises a Custom Exercise is uploaded as, or none. Strava's names are
/// English only, so they are shown as Strava has them.
struct StravaExercisePicker: View {
    @Binding var selection: String?
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var body: some View {
        List {
            if search.isEmpty {
                row(nil)
            }
            ForEach(groups, id: \.name) { group in
                Section(group.name) {
                    ForEach(group.types, id: \.self) { row($0) }
                }
            }
        }
        .searchable(text: $search)
        .navigationTitle(Text(.stravaExercise))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var groups: [StravaExerciseGroup] {
        guard !search.isEmpty else { return StravaExerciseGroup.all }
        return StravaExerciseGroup.all.compactMap { group in
            let types = group.types.filter {
                StravaExerciseGroup.displayName(of: $0).localizedStandardContains(search)
            }
            return types.isEmpty ? nil : StravaExerciseGroup(name: group.name, types: types)
        }
    }

    private func row(_ type: String?) -> some View {
        Button {
            selection = type
            dismiss()
        } label: {
            LabeledContent {
                if selection == type {
                    Image(systemName: "checkmark").foregroundStyle(.tint)
                }
            } label: {
                if let type {
                    Text(StravaExerciseGroup.displayName(of: type))
                } else {
                    Text(.stravaExerciseNone)
                }
            }
        }
        .tint(.primary)
    }
}

#Preview {
    @Previewable @State var selection: String? = "CABLE_TRICEPS_PUSHDOWN"
    NavigationStack {
        StravaExercisePicker(selection: $selection)
    }
}
