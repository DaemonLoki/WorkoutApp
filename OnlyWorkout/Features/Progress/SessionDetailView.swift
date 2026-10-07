import OnlyWorkoutConnectivity
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// Every Set of a past Session; Sets can be corrected, the Session uploaded to Strava or deleted.
struct SessionDetailView: View {
    let session: Session
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var editing: SetEntry?
    @State private var confirmsDelete = false

    var body: some View {
        List {
            ForEach(session.orderedExercises.filter { !$0.orderedSets.isEmpty }) { entry in
                Section {
                    ForEach(entry.orderedSets) { set in
                        Button {
                            editing = set
                        } label: {
                            LabeledContent {
                                Text(.repsAtWeight(set.reps, set.weight.kilograms)).monospacedDigit()
                            } label: {
                                Text(set.isExtra ? .extraSet : .setNumber(set.number))
                            }
                        }
                        .tint(.primary)
                    }
                } header: {
                    Text(entry.exerciseName)
                } footer: {
                    Text(.targetWas(String(localized: entry.target.summary)))
                }
            }
            StravaUploadSection(session: session, strava: appModel.strava)
        }
        .navigationTitle(session.workoutName)
        .navigationSubtitle(Text(session.startedAt, format: .dateTime.weekday().day().month().year()))
        .toolbar {
            Button(.deleteSession, systemImage: "trash", role: .destructive) { confirmsDelete = true }
                .confirmationDialog(Text(.deleteSessionTitle), isPresented: $confirmsDelete, titleVisibility: .visible)
            {
                Button(.deleteSession, role: .destructive) {
                    appModel.log.delete(session)
                    dismiss()
                }
            } message: {
                Text(.deleteSessionMessage)
            }
        }
        .sheet(item: $editing) { set in
            SetEditorSheet(set: set.loggedSet) { reps, weight in
                appModel.log.update(set, reps: reps, weight: weight)
            }
        }
    }
}
