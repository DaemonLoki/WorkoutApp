import Foundation
import Observation
import OnlyWorkoutStore

/// Keeps the iPhone's store and the cloud in step: push what's owed, then pull what changed (README §10).
@MainActor
@Observable
public final class CloudSync {
    /// Rows committed out of `server_updated_at` order are caught by re-pulling this much (README §10).
    static let pullOverlap: TimeInterval = 60
    static let cursorKey = "cloudSync.cursor"

    public enum Status: Equatable, Sendable {
        case signedOut
        /// Signed in, not synced yet since launch.
        case signedIn
        case syncing
        case synced(at: Date)
        /// The last attempt failed (usually offline); the next trigger retries.
        case failed
    }

    public private(set) var status = Status.signedOut

    @ObservationIgnored private let log: TrainingLog
    @ObservationIgnored private let backend: any CloudBackend
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var isRunning = false
    @ObservationIgnored private var runsAgain = false

    public init(log: TrainingLog, backend: any CloudBackend, defaults: UserDefaults = .standard) {
        self.log = log
        self.backend = backend
        self.defaults = defaults
        status = backend.isSignedIn ? .signedIn : .signedOut
    }

    public func signIn(appleIDToken: String, nonce: String) async throws {
        try await backend.signIn(appleIDToken: appleIDToken, nonce: nonce)
        await sync()
    }

    /// Local data stays; the next account starts from nothing and receives all of it.
    public func signOut() async {
        try? await backend.signOut()
        forgetCloud()
    }

    /// Deletes the account and every row in the cloud; local data stays (README §14).
    public func deleteAccount(appleAuthorizationCode: String) async throws {
        try await backend.deleteAccount(appleAuthorizationCode: appleAuthorizationCode)
        forgetCloud()
    }

    private func forgetCloud() {
        log.forgetSyncedVersions()
        cursor = nil
        status = .signedOut
    }

    /// Safe to call from every trigger: a call during a running sync makes it run once more afterwards.
    public func sync() async {
        if isRunning {
            runsAgain = true
            return
        }
        isRunning = true
        defer { isRunning = false }
        repeat {
            runsAgain = false
            await syncOnce()
        } while runsAgain
    }

    private func syncOnce() async {
        guard backend.isSignedIn else {
            status = .signedOut
            return
        }
        status = .syncing
        do {
            let pending = log.pendingPush()
            if !pending.isEmpty {
                try await backend.push(try CloudCoding.encodePush(pending))
                log.markPushed(pending)
            }
            let since = cursor?.addingTimeInterval(-Self.pullOverlap)
            let (pulled, newCursor) = try CloudCoding.decodePull(try await backend.pull(since: since))
            log.apply(pulled, fromCloud: true)
            cursor = newCursor ?? cursor
            status = .synced(at: .now)
        } catch {
            status = .failed
        }
    }

    /// Where the last pull ended; kept across launches.
    private var cursor: Date? {
        get { defaults.object(forKey: Self.cursorKey) as? Date }
        set { defaults.set(newValue, forKey: Self.cursorKey) }
    }
}
