import AuthenticationServices
import OnlyWorkoutDesign
import OnlyWorkoutSync
import SwiftUI

/// Settings → Cloud Sync: Sign in with Apple, status, sign out and account deletion (README §7, §10).
struct CloudSyncSection: View {
    let cloud: CloudSync?
    @Environment(\.colorScheme) private var colorScheme
    @State private var nonce = AppleSignInNonce()
    @State private var showsDeleteAccount = false
    @State private var showsSignInFailed = false

    var body: some View {
        Section {
            if let cloud {
                if cloud.status == .signedOut {
                    signInButton(cloud)
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
        .alert(Text(.signInFailed), isPresented: $showsSignInFailed) {
            Button(.close, role: .cancel) {}
        }
    }

    private func signInButton(_ cloud: CloudSync) -> some View {
        SignInWithAppleButton(.signIn) { request in
            nonce = AppleSignInNonce()
            // No email: nothing uses it (data minimisation, App Review guideline 5.1.1(iii)).
            request.requestedScopes = []
            request.nonce = nonce.hashed
        } onCompletion: { result in
            if case .failure(let error) = result {
                showsSignInFailed = (error as? ASAuthorizationError)?.code != .canceled
                return
            }
            guard case .success(let authorization) = result,
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken, let token = String(data: tokenData, encoding: .utf8)
            else {
                showsSignInFailed = true
                return
            }
            let rawNonce = nonce.raw
            Task {
                do {
                    try await cloud.signIn(appleIDToken: token, nonce: rawNonce)
                } catch {
                    showsSignInFailed = true
                }
            }
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(minHeight: DesignTokens.Size.minimumTapTarget)
        .clipShape(.capsule)
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
