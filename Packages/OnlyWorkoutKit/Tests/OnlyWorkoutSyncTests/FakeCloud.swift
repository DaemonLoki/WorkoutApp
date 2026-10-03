import Foundation
import OnlyWorkoutStore

@testable import OnlyWorkoutSync

/// Records what `CloudSync` sends and answers pulls with `remote`.
@MainActor
final class FakeCloud: CloudBackend {
    var isSignedIn = true
    var remote = RecordBatch()
    var cursor: Date?
    var failsPush = false

    /// Pushes wait for `releasePush()` while set.
    var holdsPush = false

    private(set) var pushes: [RecordBatch] = []
    private(set) var pulls: [Date?] = []
    private(set) var mostPushesAtOnce = 0
    private var pushesInFlight = 0
    private var heldPushes: [CheckedContinuation<Void, Never>] = []

    var isHoldingPush: Bool { !heldPushes.isEmpty }

    func releasePush() {
        holdsPush = false
        heldPushes.forEach { $0.resume() }
        heldPushes = []
    }

    private(set) var deletedAccountWith: String?

    func signIn(appleIDToken: String, nonce: String) async throws {
        isSignedIn = true
    }

    func signOut() async throws {
        isSignedIn = false
    }

    func deleteAccount(appleAuthorizationCode: String) async throws {
        deletedAccountWith = appleAuthorizationCode
        isSignedIn = false
    }

    func push(_ payload: Data) async throws {
        pushesInFlight += 1
        mostPushesAtOnce = max(mostPushesAtOnce, pushesInFlight)
        defer { pushesInFlight -= 1 }
        if holdsPush { await withCheckedContinuation { heldPushes.append($0) } }
        if failsPush { throw URLError(.notConnectedToInternet) }
        pushes.append(try CloudCoding.decodePull(payload).batch)
    }

    func pull(since: Date?) async throws -> Data {
        pulls.append(since)
        var tables = CloudTables(remote)
        tables.cursor = cursor
        return try CloudCoding.encoder.encode(tables)
    }
}
