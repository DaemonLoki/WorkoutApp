import SwiftUI

/// Sync, Apple Health and app information.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent {
                        Text(.off)
                    } label: {
                        Text(.cloudSync)
                    }
                } footer: {
                    Text(.cloudSyncFooter)
                }
                Section {
                    LabeledContent {
                        Text(.notConnected)
                    } label: {
                        Text(.appleHealth)
                    }
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
