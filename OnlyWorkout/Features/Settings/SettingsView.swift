import SwiftUI

/// Sync, Apple Health and app information.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            Form {
                CloudSyncSection(cloud: appModel.cloud)
                Section {
                    Label(.appleHealth, systemImage: "heart.text.square")
                } footer: {
                    Text(.appleHealthFooter)
                }
                Section {
                    LabeledContent {
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                    } label: {
                        Text(.version)
                    }
                } footer: {
                    Text(.privacyFooter)
                }
            }
            .navigationTitle(Text(.settings))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.close, systemImage: "checkmark") { dismiss() }
                }
            }
        }
    }
}
