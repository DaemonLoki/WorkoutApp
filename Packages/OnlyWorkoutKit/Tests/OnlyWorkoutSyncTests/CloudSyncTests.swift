import Foundation
import OnlyWorkoutCore
import OnlyWorkoutStore
import SwiftData
import Testing

@testable import OnlyWorkoutSync

/// Push, pull and account lifecycle against a fake Supabase (README §10).
@Suite("Cloud sync")
@MainActor
struct CloudSyncTests {
    let container: ModelContainer
    let cloud = FakeCloud()
    let defaults = UserDefaults(suiteName: "CloudSyncTests-\(UUID())")!
    var log: TrainingLog { TrainingLog(context: container.mainContext) }

    init() throws {
        container = try StoreContainer.make(inMemory: true)
    }

    func makeSync() -> CloudSync {
        CloudSync(log: log, backend: cloud, defaults: defaults)
    }

    @Test func aSyncPushesWhatIsOwedOnce() async throws {
        let workout = log.addWorkout(named: "Leg Day")
        let sync = makeSync()

        await sync.sync()
        await sync.sync()

        #expect(cloud.pushes.map { $0.workouts.map(\.id) } == [[workout.id]])
    }

    @Test func aSyncBringsInWhatChangedInTheCloud() async throws {
        let otherContainer = try StoreContainer.make(inMemory: true)
        let reinstalled = TrainingLog(context: otherContainer.mainContext)
        reinstalled.addWorkout(named: "Pull Day")
        cloud.remote = reinstalled.exportPlan()

        await makeSync().sync()

        #expect(log.workouts().map(\.name) == ["Pull Day"])
        #expect(log.pendingPush().isEmpty)
    }

    @Test func theNextPullOverlapsTheLastOneByAMinute() async throws {
        let cursor = Date(timeIntervalSince1970: 1_790_000_000)
        cloud.cursor = cursor

        await makeSync().sync()
        await makeSync().sync()

        #expect(cloud.pulls == [nil, Date(timeIntervalSince1970: 1_790_000_000 - 60)])
    }

    @Test func aFailedPushKeepsEverythingOwedAndSaysSo() async throws {
        let workout = log.addWorkout(named: "Leg Day")
        cloud.failsPush = true
        let sync = makeSync()

        await sync.sync()

        #expect(sync.status == .failed)
        #expect(log.pendingPush().workouts.map(\.id) == [workout.id])

        cloud.failsPush = false
        await sync.sync()

        guard case .synced = sync.status else {
            Issue.record("Expected synced, got \(sync.status)")
            return
        }
    }

    @Test func signedOutNothingLeavesThePhone() async throws {
        log.addWorkout(named: "Leg Day")
        cloud.isSignedIn = false
        let sync = makeSync()

        await sync.sync()

        #expect(cloud.pushes.isEmpty)
        #expect(cloud.pulls.isEmpty)
        #expect(sync.status == .signedOut)
    }

    @Test func syncsRequestedWhileOneRunsFollowItInsteadOfOverlapping() async throws {
        let legDay = log.addWorkout(named: "Leg Day")
        cloud.holdsPush = true
        let sync = makeSync()

        let first = Task { await sync.sync() }
        while !cloud.isHoldingPush { await Task.yield() }
        let pullDay = log.addWorkout(named: "Pull Day")
        let second = Task { await sync.sync() }
        await Task.yield()
        cloud.releasePush()
        await first.value
        await second.value

        #expect(cloud.mostPushesAtOnce == 1)
        #expect(cloud.pushes.map { Set($0.workouts.map(\.id)) } == [[legDay.id], [pullDay.id]])
    }

    @Test func signingInSyncsRightAway() async throws {
        let workout = log.addWorkout(named: "Leg Day")
        cloud.isSignedIn = false
        let sync = makeSync()

        try await sync.signIn(appleIDToken: "token", nonce: "nonce")

        #expect(cloud.pushes.map { $0.workouts.map(\.id) } == [[workout.id]])
    }

    @Test func afterSigningOutTheNextAccountGetsEverything() async throws {
        let workout = log.addWorkout(named: "Leg Day")
        cloud.cursor = Date(timeIntervalSince1970: 1_790_000_000)
        let sync = makeSync()
        await sync.sync()

        await sync.signOut()
        #expect(sync.status == .signedOut)
        #expect(log.workouts().map(\.id) == [workout.id])

        try await sync.signIn(appleIDToken: "token", nonce: "nonce")
        #expect(cloud.pushes.count == 2)
        #expect(cloud.pushes.last?.workouts.map(\.id) == [workout.id])
        #expect(cloud.pulls.last == .some(nil))
    }

    @Test func deletingTheAccountKeepsThePhonesData() async throws {
        let workout = log.addWorkout(named: "Leg Day")
        let sync = makeSync()
        await sync.sync()

        try await sync.deleteAccount(appleAuthorizationCode: "code")

        #expect(cloud.deletedAccountWith == "code")
        #expect(sync.status == .signedOut)
        #expect(log.workouts().map(\.id) == [workout.id])
        #expect(log.pendingPush().workouts.map(\.id) == [workout.id])
    }

    @Test func aSignInRestoredAtLaunchShowsBeforeTheFirstSync() {
        #expect(makeSync().status == .signedIn)

        cloud.isSignedIn = false
        #expect(makeSync().status == .signedOut)
    }
}
