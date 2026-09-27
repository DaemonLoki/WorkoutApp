import SwiftUI

/// Shown when every Set is logged, until the user finishes the Session.
struct AllSetsDoneView: View {
    let onFinish: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(.allSetsDone, systemImage: "checkmark.circle")
        } description: {
            Text(.allSetsDoneMessage)
        } actions: {
            Button(action: onFinish) {
                Text(.finishSession).font(.headline).frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .accessibilityIdentifier("finishSessionButton")
        }
    }
}
