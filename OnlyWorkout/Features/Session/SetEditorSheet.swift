import OnlyWorkoutCore
import SwiftUI

/// Corrects the reps and weight of a logged Set.
struct SetEditorSheet: View {
    let onSave: (_ reps: Int, _ weight: Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var reps: Int
    @State private var weight: Double
    @FocusState private var weightIsFocused: Bool

    init(set: LoggedSet, onSave: @escaping (_ reps: Int, _ weight: Double) -> Void) {
        self.onSave = onSave
        _reps = State(initialValue: set.reps)
        _weight = State(initialValue: set.weight)
    }

    var body: some View {
        NavigationStack {
            Form {
                Stepper(value: $reps, in: 0...100) {
                    LabeledContent {
                        Text(reps, format: .number)
                    } label: {
                        Text(.reps)
                    }
                }
                WeightField(title: .weightKg, weight: $weight, isFocused: $weightIsFocused)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(Text(.editSet))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.cancel, systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.save, systemImage: "checkmark") {
                        onSave(reps, max(0, weight))
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(.done) { weightIsFocused = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
