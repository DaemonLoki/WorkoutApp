import SwiftUI

/// Sync, Strava, Apple Health, Sessions, Apple Watch and app information.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel
    @AppStorage(AppModel.startsSessionsOnWatchKey) private var startsSessionsOnWatch = true
    @AppStorage(AppModel.usesRestTimerKey) private var usesRestTimer = true

    var body: some View {
        NavigationStack {
            Form {
                CloudSyncSection(cloud: appModel.cloud)
                StravaSection(strava: appModel.strava, cloud: appModel.cloud)
                Section {
                    Label(.appleHealth, systemImage: "heart.text.square")
                } footer: {
                    Text(.appleHealthFooter)
                }
                Section {
                    Toggle(isOn: $usesRestTimer) {
                        Text(.restTimer)
                    }
                    .onChange(of: usesRestTimer) { appModel.publishToWatch() }
                } header: {
                    Text(.sessionsSettings)
                } footer: {
                    Text(.restTimerFooter)
                }
                Section {
                    Toggle(isOn: $startsSessionsOnWatch) {
                        Text(.startsSessionsOnWatch)
                    }
                } header: {
                    Text(.appleWatch)
                } footer: {
                    Text(.startsSessionsOnWatchFooter)
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
