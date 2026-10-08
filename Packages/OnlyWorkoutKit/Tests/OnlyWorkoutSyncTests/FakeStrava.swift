import Foundation

@testable import OnlyWorkoutSync

/// Stands in for the `strava-*` Edge Functions; records uploads and answers with `outcome`.
@MainActor
final class FakeStrava: StravaBackend {
    var isSignedIn = true
    var connection: StravaConnection?
    var outcome = StravaUploadOutcome.uploaded(activityID: 16_000_000_001)
    var failsUpload = false
    /// `strava_connect_open()`: a slot is free, or this user is connected already.
    var isConnectOpen = true
    /// Strava refuses the token exchange because the API app's capacity is used up.
    var refusesForAthleteLimit = false

    private(set) var connectedWith: [String] = []
    private(set) var uploads: [StravaUploadRequest] = []
    private(set) var disconnects = 0

    func stravaConnection() async throws -> StravaConnection? {
        connection
    }

    func stravaConnectOpen() async throws -> Bool {
        isConnectOpen
    }

    func connectStrava(authorizationCode: String) async throws -> StravaConnection {
        if refusesForAthleteLimit { throw StravaBackendError.athleteLimitReached }
        connectedWith.append(authorizationCode)
        let connection = StravaConnection(connectedAt: Date(timeIntervalSince1970: 1_790_000_000), autoUpload: true)
        self.connection = connection
        return connection
    }

    func setStravaAutoUpload(_ isOn: Bool) async throws {
        connection?.autoUpload = isOn
    }

    func disconnectStrava() async throws {
        disconnects += 1
        connection = nil
    }

    func uploadToStrava(_ upload: StravaUploadRequest) async throws -> StravaUploadOutcome {
        if failsUpload { throw URLError(.notConnectedToInternet) }
        guard connection != nil else { throw StravaBackendError.notConnected }
        uploads.append(upload)
        return outcome
    }
}
