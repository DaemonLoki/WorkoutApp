import Foundation

/// What `StravaLink` needs from the cloud: the `strava-*` Edge Functions and the connection RPCs
/// (README §12). `SupabaseBackend` is the real one; Strava's tokens never reach the app.
@MainActor
public protocol StravaBackend: AnyObject {
    /// Signed in to the cloud; Strava rides on that account.
    var isSignedIn: Bool { get }
    /// `nil` when no Strava account is connected.
    func stravaConnection() async throws -> StravaConnection?
    /// Whether connecting can work: a slot of the Strava API app's athlete capacity is free, or the user
    /// is connected already (`strava_connect_open()`).
    func stravaConnectOpen() async throws -> Bool
    /// Hands the one-time code from Strava's redirect to `strava-connect`, which swaps it for tokens.
    func connectStrava(authorizationCode: String) async throws -> StravaConnection
    func setStravaAutoUpload(_ isOn: Bool) async throws
    /// Revokes the tokens at Strava and deletes them (`strava-disconnect`).
    func disconnectStrava() async throws
    /// Posts the file through `strava-upload`, which waits briefly for Strava to process it.
    func uploadToStrava(_ upload: StravaUploadRequest) async throws -> StravaUploadOutcome
}

public struct StravaConnection: Codable, Equatable, Sendable {
    public var connectedAt: Date
    /// Upload every Session finished after connecting, without asking.
    public var autoUpload: Bool

    public init(connectedAt: Date, autoUpload: Bool) {
        self.connectedAt = connectedAt
        self.autoUpload = autoUpload
    }
}

public struct StravaUploadRequest: Equatable, Sendable {
    public var sessionID: UUID
    /// The activity's title on Strava: the Workout name.
    public var name: String
    /// `StravaUpload.file()`.
    public var file: Data
}

public enum StravaUploadOutcome: Equatable, Sendable {
    /// Strava created the activity, or already had it from an earlier upload of the same Session.
    case uploaded(activityID: Int64)
    /// Strava hadn't finished processing in time; uploading again later finds it as a duplicate.
    case stillProcessing
}

public enum StravaBackendError: Error, Equatable {
    /// No Strava connection in the cloud, e.g. revoked on Strava's side.
    case notConnected
    /// Strava's athlete capacity for the API app is used up; nobody new can connect for now.
    case athleteLimitReached
    /// Strava refused the file; `detail` is Strava's English message.
    case rejected(detail: String)
    /// Over Strava's rate limit, or Strava itself failed; try again later.
    case unavailable
}
