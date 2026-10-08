import Foundation
import OnlyWorkoutCore
import OnlyWorkoutStore
import SwiftData
import Testing

@testable import OnlyWorkoutSync

/// Connecting, uploading and disconnecting Strava against fake Edge Functions (README §12).
@Suite("Strava link")
@MainActor
struct StravaLinkTests {
    let container: ModelContainer
    let strava = FakeStrava()
    var log: TrainingLog { TrainingLog(context: container.mainContext) }

    init() throws {
        container = try StoreContainer.make(inMemory: true)
        try ExerciseCatalog.seed(into: container.mainContext)
    }

    let connectedAt = Date(timeIntervalSince1970: 1_790_000_000)

    /// A finished Leg Day of one Squat Set, `hours` after connecting.
    @discardableResult
    func finishedSession(hoursAfterConnecting hours: Double) throws -> Session {
        let workout = log.workouts().first ?? log.addWorkout(named: "Leg Day")
        if workout.orderedPlannedExercises.isEmpty {
            let key = "back-squat"
            let squat = try #require(
                try log.context.fetch(FetchDescriptor<Exercise>(predicate: #Predicate { $0.catalogKey == key })).first)
            log.add(squat, to: workout).targetSets = 1
        }
        let start = connectedAt.addingTimeInterval(hours * 3_600)
        let (session, engine) = log.startSession(workout, now: start)
        let runner = SessionRunner(session: session, engine: engine, log: log, now: { start.addingTimeInterval(600) })
        runner.completeSet(reps: 5, weight: 80)
        runner.finish()
        return session
    }

    func connectedLink(autoUpload: Bool = true) async throws -> StravaLink {
        strava.connection = StravaConnection(connectedAt: connectedAt, autoUpload: autoUpload)
        let link = makeLink()
        await link.refresh()
        return link
    }

    func makeLink() -> StravaLink {
        StravaLink(log: log, backend: strava, creator: "OnlyWorkout", timeZone: TimeZone(identifier: "Europe/Berlin")!)
    }

    /// What Strava's consent page sends back to the app.
    func redirect(_ query: String) throws -> URL {
        try #require(URL(string: "onlyworkouts://onlyworkout.stefanblos.com/strava?\(query)"))
    }

    func state(of authorization: URL) throws -> String {
        let items = URLComponents(url: authorization, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return try #require(items.first { $0.name == "state" }?.value)
    }

    @Test func aRedirectThatAllowsUploadsConnects() async throws {
        let link = makeLink()
        let state = try state(of: link.authorizationURL(clientID: "12345"))

        try await link.finishConnecting(redirect: try redirect("state=\(state)&code=abc123&scope=read,activity:write"))

        #expect(strava.connectedWith == ["abc123"])
        let connectedAt = Date(timeIntervalSince1970: 1_790_000_000)
        #expect(link.status == .connected(StravaConnection(connectedAt: connectedAt, autoUpload: true)))
    }

    /// Strava separates scopes with commas in the redirect but with spaces in its token answer.
    @Test func aRedirectWithSpaceSeparatedScopesConnects() async throws {
        let link = makeLink()
        let state = try state(of: link.authorizationURL(clientID: "12345"))

        try await link.finishConnecting(
            redirect: try redirect("state=\(state)&code=abc123&scope=read%20activity:write"))

        #expect(strava.connectedWith == ["abc123"])
    }

    /// Strava's consent page lets the user untick uploads; the code would be useless then.
    @Test func aRedirectWithoutUploadPermissionIsRefusedAndNothingIsConnected() async throws {
        let link = makeLink()
        let state = try state(of: link.authorizationURL(clientID: "12345"))

        await #expect(throws: StravaLink.ConnectError.uploadsNotAllowed) {
            try await link.finishConnecting(redirect: try redirect("state=\(state)&code=abc123&scope=read"))
        }
        #expect(strava.connectedWith.isEmpty)
    }

    @Test func aRedirectFromAnotherConsentPageIsRefused() async throws {
        let link = makeLink()
        _ = link.authorizationURL(clientID: "12345")

        await #expect(throws: StravaLink.ConnectError.unexpectedRedirect) {
            try await link.finishConnecting(redirect: try redirect("state=forged&code=abc123&scope=activity:write"))
        }
        #expect(strava.connectedWith.isEmpty)
    }

    @Test func autoUploadSendsEachSessionFinishedSinceConnectingOnce() async throws {
        try finishedSession(hoursAfterConnecting: -24)
        let session = try finishedSession(hoursAfterConnecting: 2)
        let link = try await connectedLink()

        await link.uploadPending()
        await link.uploadPending()

        #expect(strava.uploads.map(\.sessionID) == [session.id])
        #expect(strava.uploads.first?.name == "Leg Day")
        #expect(session.stravaActivityID == 16_000_000_001)
    }

    @Test func withAutoUploadOffOnlyAManualUploadSendsEvenAnOlderSession() async throws {
        let older = try finishedSession(hoursAfterConnecting: -24)
        try finishedSession(hoursAfterConnecting: 2)
        let link = try await connectedLink(autoUpload: false)

        await link.uploadPending()
        #expect(strava.uploads.isEmpty)

        try await link.upload(older)
        #expect(strava.uploads.map(\.sessionID) == [older.id])
        #expect(older.stravaUploadedAt != nil)
    }

    @Test func aSessionWhoseUploadFailedIsSentAgainOnTheNextTrigger() async throws {
        let session = try finishedSession(hoursAfterConnecting: 2)
        let link = try await connectedLink()
        strava.failsUpload = true
        await link.uploadPending()
        #expect(session.stravaUploadedAt == nil)

        strava.failsUpload = false
        await link.uploadPending()

        #expect(strava.uploads.map(\.sessionID) == [session.id])
        #expect(session.stravaUploadedAt != nil)
    }

    @Test func afterDisconnectingNothingIsUploaded() async throws {
        try finishedSession(hoursAfterConnecting: 2)
        let link = try await connectedLink()

        try await link.disconnect()
        await link.uploadPending()

        #expect(strava.disconnects == 1)
        #expect(link.status == .notConnected)
        #expect(strava.uploads.isEmpty)
    }

    /// Revoked on Strava's side before the webhook reached the cloud.
    @Test func anUploadRefusedBecauseAccessWasRevokedShowsStravaAsNotConnected() async throws {
        let session = try finishedSession(hoursAfterConnecting: 2)
        let link = try await connectedLink()
        strava.connection = nil

        await #expect(throws: StravaBackendError.notConnected) { try await link.upload(session) }

        #expect(link.status == .notConnected)
        #expect(session.stravaUploadedAt == nil)
    }
}
