import AuthenticationServices
import OnlyWorkoutSync
import SwiftUI
import os

/// Settings → Strava: connect through Strava's consent page, auto-upload, disconnect (README §12).
struct StravaSection: View {
    let strava: StravaLink?
    let cloud: CloudSync?
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @State private var isBusy = false
    @State private var failure: (title: LocalizedStringResource, message: LocalizedStringResource)?
    @State private var confirmsDisconnect = false

    var body: some View {
        Section {
            if let strava, let clientID = CloudServices.stravaClientID, isSignedIn {
                switch strava.status {
                case .unknown:
                    LabeledContent {
                        ProgressView()
                    } label: {
                        Text(.strava)
                    }
                case .notConnected:
                    // Strava's brand guidelines: the official button, unmodified, 48 pt tall.
                    Button {
                        connect(strava, clientID: clientID)
                    } label: {
                        Image(.connectWithStrava)
                            .accessibilityLabel(Text(.connectWithStrava))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .disabled(isBusy)
                case .connected(let connection):
                    LabeledContent {
                        Text(.stravaConnected)
                    } label: {
                        Text(.strava)
                    }
                    Toggle(isOn: autoUpload(strava, connection)) {
                        Text(.stravaUploadAutomatically)
                    }
                    Button(.disconnectStrava, role: .destructive) { confirmsDisconnect = true }
                        .disabled(isBusy)
                }
            } else {
                LabeledContent {
                    Text(.off)
                } label: {
                    Text(.strava)
                }
            }
        } footer: {
            Text(footer)
        }
        .task { await strava?.refresh() }
        .confirmationDialog(Text(.disconnectStravaTitle), isPresented: $confirmsDisconnect, titleVisibility: .visible) {
            Button(.disconnectStrava, role: .destructive) { disconnect() }
        } message: {
            Text(.disconnectStravaMessage)
        }
        .alert(Text(failure?.title ?? .strava), isPresented: isFailing) {
            Button(.close, role: .cancel) {}
        } message: {
            if let failure { Text(failure.message) }
        }
    }

    private var isSignedIn: Bool {
        cloud.map { $0.status != .signedOut } ?? false
    }

    private var footer: LocalizedStringResource {
        guard strava != nil, CloudServices.stravaClientID != nil else { return .stravaUnavailableFooter }
        guard isSignedIn else { return .stravaNeedsCloudFooter }
        if case .connected = strava?.status { return .stravaConnectedFooter }
        return .stravaConsentFooter
    }

    private var isFailing: Binding<Bool> {
        Binding {
            failure != nil
        } set: {
            if !$0 { failure = nil }
        }
    }

    private func autoUpload(_ strava: StravaLink, _ connection: StravaConnection) -> Binding<Bool> {
        Binding {
            connection.autoUpload
        } set: { isOn in
            Task { try? await strava.setAutoUpload(isOn) }
        }
    }

    private func connect(_ strava: StravaLink, clientID: String) {
        isBusy = true
        Task {
            defer { isBusy = false }
            do {
                let redirect = try await webAuthenticationSession.authenticate(
                    using: strava.authorizationURL(clientID: clientID),
                    callback: .customScheme(StravaLink.callbackScheme), preferredBrowserSession: .shared,
                    additionalHeaderFields: [:])
                try await strava.finishConnecting(redirect: redirect)
                await strava.uploadPending()
            } catch ASWebAuthenticationSessionError.canceledLogin, StravaLink.ConnectError.declined {
                // The user changed their mind.
            } catch StravaLink.ConnectError.uploadsNotAllowed {
                failure = (.stravaConnectFailed, .stravaUploadsNotAllowed)
            } catch {
                Logger.strava.error("Connecting failed: \(String(describing: error), privacy: .public)")
                failure = (.stravaConnectFailed, .stravaTryAgainLater)
            }
        }
    }

    private func disconnect() {
        guard let strava else { return }
        isBusy = true
        Task {
            defer { isBusy = false }
            do {
                try await strava.disconnect()
            } catch {
                Logger.strava.error("Disconnecting failed: \(String(describing: error), privacy: .public)")
                failure = (.disconnectStrava, .stravaTryAgainLater)
            }
        }
    }
}
