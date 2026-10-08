import OnlyWorkoutStore
import SwiftUI

/// A Session in History: opens its detail; swipe to delete after a confirmation.
struct HistoryRow: View {
    let session: Session
    @Environment(AppModel.self) private var appModel
    @State private var confirmsDelete = false

    var body: some View {
        NavigationLink(value: session) {
            SessionRow(session: session)
        }
        .swipeActions {
            // Not `.destructive`: the row stays until the deletion is confirmed.
            Button(.deleteSession, systemImage: "trash") { confirmsDelete = true }
                .tint(.red)
        }
        .confirmationDialog(Text(.deleteSessionTitle), isPresented: $confirmsDelete, titleVisibility: .visible) {
            Button(.deleteSession, role: .destructive) { appModel.delete(session) }
        } message: {
            Text(.deleteSessionMessage)
        }
    }
}
