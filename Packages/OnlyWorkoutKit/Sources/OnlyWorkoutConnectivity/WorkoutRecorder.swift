#if canImport(HealthKit) && !os(macOS)
import Foundation
import HealthKit
import Observation

/// Records a Session as an Apple Health strength workout (README §11) and carries the mirroring channel
/// between Watch and iPhone. On the Watch it measures heart rate and energy; on the iPhone it either runs
/// its own session (iPhone-only Session) or attaches to the one mirrored from the Watch.
@Observable
@MainActor
public final class WorkoutRecorder {
    public private(set) var heartRate: Double?
    public private(set) var isRunning = false

    /// Data sent by the other device over the mirrored session.
    @ObservationIgnored public var onRemoteData: ((Data) -> Void)?
    /// The other device ended the mirrored session.
    @ObservationIgnored public var onRemoteEnd: (() -> Void)?

    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private var session: HKWorkoutSession?
    @ObservationIgnored private var builder: HKLiveWorkoutBuilder?
    @ObservationIgnored private lazy var delegate = HealthDelegate(
        onData: { [weak self] data in Task { @MainActor in self?.onRemoteData?(data) } },
        onHeartRate: { [weak self] bpm in Task { @MainActor in self?.heartRate = bpm } },
        onEnded: { [weak self] in
            Task { @MainActor in
                self?.isRunning = false
                self?.onRemoteEnd?()
            }
        })

    public init() {}

    public static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private static var typesToShare: Set<HKSampleType> {
        [HKObjectType.workoutType(), HKQuantityType(.activeEnergyBurned), HKQuantityType(.heartRate)]
    }

    private static var typesToRead: Set<HKObjectType> {
        [HKQuantityType(.heartRate), HKQuantityType(.activeEnergyBurned)]
    }

    /// Whether the system permission sheet still has to be shown.
    public func needsAuthorization() async -> Bool {
        guard Self.isAvailable else { return false }
        let status = try? await store.statusForAuthorizationRequest(toShare: Self.typesToShare, read: Self.typesToRead)
        return status == .shouldRequest
    }

    public func requestAuthorization() async {
        guard Self.isAvailable else { return }
        try? await store.requestAuthorization(toShare: Self.typesToShare, read: Self.typesToRead)
    }

    private var configuration: HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        return configuration
    }

    /// Starts recording. `mirrorToCompanion` is used on the Watch so the iPhone can follow along.
    public func start(at date: Date, mirrorToCompanion: Bool) async {
        guard Self.isAvailable, session == nil else { return }
        do {
            let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
            session.delegate = delegate
            builder.delegate = delegate
            self.session = session
            self.builder = builder
            session.startActivity(with: date)
            try await builder.beginCollection(at: date)
            isRunning = true
            #if os(watchOS)
            if mirrorToCompanion {
                try? await session.startMirroringToCompanionDevice()
            }
            #endif
        } catch {
            session = nil
            builder = nil
        }
    }

    /// Resumes a workout session the system kept alive while the app was terminated (Watch).
    public func recover() async -> Bool {
        guard Self.isAvailable, let recovered = try? await store.recoverActiveWorkoutSession() else { return false }
        attach(recovered)
        builder = recovered.associatedWorkoutBuilder()
        builder?.delegate = delegate
        return true
    }

    /// Ends recording and saves the workout to Health. Returns the saved workout's id.
    @discardableResult
    public func finish(at date: Date) async -> UUID? {
        guard let session else { return nil }
        session.stopActivity(with: date)
        session.end()
        defer {
            self.session = nil
            self.builder = nil
            isRunning = false
        }
        guard let builder else { return nil }
        do {
            try await builder.endCollection(at: date)
            return try await builder.finishWorkout()?.uuid
        } catch {
            return nil
        }
    }

    /// Sends data to the other device over the mirrored session.
    public func send(_ data: Data) async {
        try? await session?.sendToRemoteWorkoutSession(data: data)
    }

    /// Deletes a workout this app saved, e.g. when its Session is deleted.
    public static func deleteWorkout(id: UUID) async {
        let store = HKHealthStore()
        let predicate = HKQuery.predicateForObject(with: id)
        _ = try? await store.deleteObjects(of: HKObjectType.workoutType(), predicate: predicate)
    }

    private func attach(_ session: HKWorkoutSession) {
        session.delegate = delegate
        self.session = session
        isRunning = true
    }
}

#if os(iOS)
extension WorkoutRecorder {
    /// Launches the Watch app so it can run the Session; fails if no Watch is reachable.
    public func startWatchApp() async throws {
        try await store.startWatchApp(toHandle: configuration)
    }

    /// Calls `handler` whenever the Watch starts mirroring a Session to this iPhone. Must be set at launch.
    public func observeMirroredSessions(_ handler: @escaping @MainActor () -> Void) {
        store.workoutSessionMirroringStartHandler = { [weak self] mirrored in
            let box = UncheckedSendable(mirrored)
            Task { @MainActor in
                self?.attach(box.value)
                handler()
            }
        }
    }
}
#endif

/// Hands a HealthKit object (not `Sendable`) from HealthKit's queue to the main actor; it is used there only.
private struct UncheckedSendable<Value>: @unchecked Sendable {
    let value: Value
    init(_ value: Value) { self.value = value }
}

/// Receives HealthKit callbacks on HealthKit's queues and forwards plain values.
private final class HealthDelegate: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, Sendable {
    let onData: @Sendable (Data) -> Void
    let onHeartRate: @Sendable (Double) -> Void
    let onEnded: @Sendable () -> Void

    init(
        onData: @escaping @Sendable (Data) -> Void, onHeartRate: @escaping @Sendable (Double) -> Void,
        onEnded: @escaping @Sendable () -> Void
    ) {
        self.onData = onData
        self.onHeartRate = onHeartRate
        self.onEnded = onEnded
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState, date: Date
    ) {
        if toState == .ended { onEnded() }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        data.forEach(onData)
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didDisconnectFromRemoteDeviceWithError error: (any Error)?) {
        onEnded()
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let heartRate = HKQuantityType(.heartRate)
        guard collectedTypes.contains(heartRate),
            let quantity = workoutBuilder.statistics(for: heartRate)?.mostRecentQuantity()
        else { return }
        onHeartRate(quantity.doubleValue(for: .count().unitDivided(by: .minute())))
    }
}
#endif
