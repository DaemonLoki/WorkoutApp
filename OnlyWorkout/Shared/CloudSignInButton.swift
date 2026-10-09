import AuthenticationServices
import OnlyWorkoutDesign
import OnlyWorkoutSync
import SwiftUI

/// Sign in with Apple for Cloud Sync, used by Settings and by onboarding's restore page, so the nonce and the
/// request are handled in one place (README §10). A failed sign-in shows an alert; a cancelled one shows nothing.
struct CloudSignInButton: View {
    let cloud: CloudSync
    /// `true` from the Apple sheet's completion until Cloud Sync's sign-in (push, then pull) has finished.
    @Binding var isSigningIn: Bool
    /// Runs once that sign-in succeeded.
    let onSignedIn: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var nonce = AppleSignInNonce()
    @State private var showsSignInFailed = false

    init(cloud: CloudSync, isSigningIn: Binding<Bool> = .constant(false), onSignedIn: @escaping () -> Void = {}) {
        self.cloud = cloud
        _isSigningIn = isSigningIn
        self.onSignedIn = onSignedIn
    }

    var body: some View {
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
            isSigningIn = true
            Task {
                do {
                    try await cloud.signIn(appleIDToken: token, nonce: rawNonce)
                    isSigningIn = false
                    onSignedIn()
                } catch {
                    isSigningIn = false
                    showsSignInFailed = true
                }
            }
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(minHeight: DesignTokens.Size.minimumTapTarget)
        .clipShape(.capsule)
        .alert(Text(.signInFailed), isPresented: $showsSignInFailed) {
            Button(.close, role: .cancel) {}
        }
    }
}
