import Foundation
import Observation
import OnlyWorkoutCore
import OnlyWorkoutStore
import os

/// The iPhone's side of Strava: connect through Strava's consent page, upload finished Sessions,
/// disconnect (README §12). Tokens stay in the cloud; this only ever sees the one-time code.
@MainActor
@Observable
public final class StravaLink {
    public static let callbackScheme = "onlyworkouts"
    /// Inside the callback domain registered for the Strava API app.
    static let redirectURI = "onlyworkouts://onlyworkout.stefanblos.com/strava"

    public enum Status: Equatable, Sendable {
        /// Not loaded yet.
        case unknown
        case notConnected
        case connected(StravaConnection)
    }

    public enum ConnectError: Error, Equatable {
        /// The redirect doesn't belong to the consent page this link opened.
        case unexpectedRedirect
        /// The user unticked "Upload your activities" on the consent page.
        case uploadsNotAllowed
        /// The user cancelled on the consent page.
        case declined
    }

    public enum UploadError: Error, Equatable {
        /// No Set has a Strava exercise type, e.g. only Custom Exercises without one.
        case nothingToUpload
        /// Strava is still processing; the next upload of the Session finds the activity.
        case stillProcessing
    }

    public private(set) var status = Status.unknown
    /// Sessions on their way to Strava right now.
    public private(set) var uploading: Set<UUID> = []

    @ObservationIgnored private let log: TrainingLog
    @ObservationIgnored private let backend: any StravaBackend
    @ObservationIgnored private let creator: String
    @ObservationIgnored private let timeZone: TimeZone
    @ObservationIgnored private var pendingState: String?
    @ObservationIgnored private var isUploading = false
    /// Called after a Session got its upload mark, so the mark can sync.
    @ObservationIgnored public var didUpload: (() -> Void)?

    /// `creator` names the app on Strava's activity.
    public init(log: TrainingLog, backend: any StravaBackend, creator: String, timeZone: TimeZone = .current) {
        self.log = log
        self.backend = backend
        self.creator = creator
        self.timeZone = timeZone
    }

    /// Strava's consent page asking for `activity:write` only; open it in `ASWebAuthenticationSession`.
    public func authorizationURL(clientID: String) -> URL {
        let state = UUID().uuidString
        pendingState = state
        var components = URLComponents(string: "https://www.strava.com/oauth/mobile/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: Self.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: "activity:write"),
            URLQueryItem(name: "state", value: state),
        ]
        return components.url!
    }

    /// Takes the redirect from Strava's consent page and connects through `strava-connect`.
    public func finishConnecting(redirect: URL) async throws {
        let items = URLComponents(url: redirect, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }
        guard let state = pendingState, value("state") == state else {
            // Names only: the values include the one-time code.
            let names = items.map(\.name).joined(separator: ",")
            Logger.strava.error(
                "Unexpected redirect (pending state: \(self.pendingState != nil), parameters: \(names, privacy: .public))"
            )
            throw ConnectError.unexpectedRedirect
        }
        pendingState = nil
        guard let code = value("code") else { throw ConnectError.declined }
        let scopes = (value("scope") ?? "").split { $0 == "," || $0 == " " }
        guard scopes.contains("activity:write") else {
            Logger.strava.error("Strava granted only \(value("scope") ?? "nothing", privacy: .public)")
            throw ConnectError.uploadsNotAllowed
        }
        status = .connected(try await backend.connectStrava(authorizationCode: code))
    }

    /// Revokes access at Strava and forgets the tokens; Sessions and their upload marks stay.
    public func disconnect() async throws {
        try await backend.disconnectStrava()
        status = .notConnected
    }

    public func setAutoUpload(_ isOn: Bool) async throws {
        guard case .connected(var connection) = status else { return }
        try await backend.setStravaAutoUpload(isOn)
        connection.autoUpload = isOn
        status = .connected(connection)
    }

    /// Loads the connection from the cloud and forgets activity IDs past their 7 days.
    public func refresh() async {
        log.forgetExpiredStravaActivityIDs()
        guard backend.isSignedIn else {
            status = .notConnected
            return
        }
        do {
            status = try await backend.stravaConnection().map(Status.connected) ?? .notConnected
        } catch {
            // Offline: keep what we knew.
        }
    }

    /// With auto-upload on, uploads every Session finished since connecting that isn't on Strava yet.
    /// Safe to call from every trigger; failures stay queued for the next one.
    public func uploadPending() async {
        guard case .connected(let connection) = status, connection.autoUpload, !isUploading else { return }
        isUploading = true
        defer { isUploading = false }
        for session in log.sessionsAwaitingStravaUpload(finishedSince: connection.connectedAt) {
            do {
                try await upload(session)
            } catch UploadError.nothingToUpload {
                continue
            } catch {
                Logger.strava.error("Upload failed: \(String(describing: error), privacy: .public)")
                return  // offline or Strava busy: the rest waits for the next trigger
            }
        }
    }

    /// Uploads one finished Session, e.g. from Session detail.
    public func upload(_ session: Session) async throws {
        guard let upload = log.stravaUpload(of: session, creator: creator, timeZone: timeZone) else {
            throw UploadError.nothingToUpload
        }
        let request = StravaUploadRequest(sessionID: session.id, name: session.workoutName, file: try upload.file())
        uploading.insert(session.id)
        defer { uploading.remove(session.id) }
        let outcome: StravaUploadOutcome
        do {
            outcome = try await backend.uploadToStrava(request)
        } catch StravaBackendError.notConnected {
            status = .notConnected
            throw StravaBackendError.notConnected
        }
        guard case .uploaded(let activityID) = outcome else { throw UploadError.stillProcessing }
        log.markUploadedToStrava(session, activityID: activityID)
        didUpload?()
    }
}
