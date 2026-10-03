import AuthenticationServices
import OnlyWorkoutDesign
import OnlyWorkoutSync
import SwiftUI

/// Confirms account deletion with Sign in with Apple, whose fresh authorization code lets
/// `delete-account` revoke the Apple token (README §14).
struct DeleteAccountView: View {
    let cloud: CloudSync
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isDeleting = false
    @State private var showsFailed = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.l) {
                Text(.deleteAccountMessage)
                    .foregroundStyle(.secondary)
                Spacer()
                if isDeleting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = []
                    } onCompletion: { result in
                        confirm(result)
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(minHeight: DesignTokens.Size.minimumTapTarget)
                    .clipShape(.capsule)
                }
            }
            .padding()
            .navigationTitle(Text(.deleteAccountTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.cancel, systemImage: "xmark") { dismiss() }
                        .disabled(isDeleting)
                }
            }
            .alert(Text(.deleteAccountFailed), isPresented: $showsFailed) {
                Button(.close, role: .cancel) {}
            }
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled(isDeleting)
    }

    private func confirm(_ result: Result<ASAuthorization, any Error>) {
        if case .failure(let error) = result {
            showsFailed = (error as? ASAuthorizationError)?.code != .canceled
            return
        }
        guard case .success(let authorization) = result,
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let codeData = credential.authorizationCode, let code = String(data: codeData, encoding: .utf8)
        else {
            showsFailed = true
            return
        }
        isDeleting = true
        Task {
            do {
                try await cloud.deleteAccount(appleAuthorizationCode: code)
                dismiss()
            } catch {
                isDeleting = false
                showsFailed = true
            }
        }
    }
}
