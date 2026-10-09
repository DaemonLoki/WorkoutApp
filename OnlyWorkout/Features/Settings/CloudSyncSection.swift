import OnlyWorkoutDesign
import OnlyWorkoutSync
import SwiftUI

/// Settings → Cloud Sync: Sign in with Apple, status, sign out and account deletion (README §7, §10).
struct CloudSyncSection: View {
    let cloud: CloudSync?
    @State private var showsDeleteAccount = false

    var body: some View {
        Section {
            if let cloud {
                if cloud.status == .signedOut {
                    CloudSignInButton(cloud: cloud)
                } else {
                    LabeledContent {
                        Text(status(cloud.status))
                    } label: {
                        Text(.cloudSync)
                    }
                    Button(.signOut) {
                        Task { await cloud.signOut() }
                    }
                    Button(.deleteAccount, role: .destructive) { showsDeleteAccount = true }
                }
            } else {
                LabeledContent {
                    Text(.off)
                } label: {
                    Text(.cloudSync)
                }
            }
        } footer: {
            Text(cloud == nil ? .cloudSyncUnavailableFooter : .cloudSyncFooter)
        }
        .sheet(isPresented: $showsDeleteAccount) {
            if let cloud {
                DeleteAccountView(cloud: cloud)
            }
        }
    }

    private func status(_ status: CloudSync.Status) -> LocalizedStringResource {
        switch status {
        case .signedOut, .signedIn: .syncSignedIn
        case .syncing: .syncSyncing
        case .synced(let date): .syncSyncedAgo(date.formatted(.relative(presentation: .named)))
        case .failed: .syncFailed
        }
    }
}
