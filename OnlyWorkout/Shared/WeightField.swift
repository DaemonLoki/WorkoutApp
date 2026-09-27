import OnlyWorkoutDesign
import SwiftUI

/// A kg entry field that clears when focused so a new weight can be typed from scratch;
/// the current weight stays visible as the placeholder, and leaving it empty keeps that weight.
///
/// Backed by text rather than `TextField(value:format:)` because the value-based field
/// can't be emptied without committing a value.
struct WeightField: View {
    let title: LocalizedStringResource
    @Binding var weight: Double
    var isFocused: FocusState<Bool>.Binding

    @State private var text = ""

    var body: some View {
        LabeledContent {
            TextField(text: $text, prompt: Text(weight.weightNumber)) {
                Text(title)
            }
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .focused(isFocused)
            .accessibilityIdentifier("weightField")
        } label: {
            Text(title)
        }
        .onAppear { text = weight.weightNumber }
        .onChange(of: isFocused.wrappedValue) { _, focused in
            text = focused ? "" : weight.weightNumber
        }
        .onChange(of: text) { _, newText in
            if let value = try? Double(newText, format: .number) {
                weight = max(0, value)
            }
        }
    }
}
