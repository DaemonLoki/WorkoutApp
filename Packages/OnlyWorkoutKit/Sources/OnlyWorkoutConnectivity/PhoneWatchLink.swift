#if canImport(WatchConnectivity)
import Foundation
import Observation
import OnlyWorkoutStore
import WatchConnectivity

/// Moves records between iPhone and Watch (README §8, ADR-0002):
/// the iPhone publishes the plan snapshot as application context; the Watch queues finished Sessions
/// with `transferUserInfo`, which is delivered even if the iPhone is away for hours.
@Observable
@MainActor
public final class PhoneWatchLink {
    /// How long the iPhone waits for the Watch to take over a Session before running it itself.
    /// The Watch ignores requests older than this, so a Session never runs on both.
    public nonisolated static let watchStartTimeout: Duration = .seconds(8)

    /// A request from the iPhone to start this Workout on the Watch.
    public struct StartRequest: Codable, Sendable {
        public var workoutID: UUID
        public var requestedAt: Date

        /// Still within the iPhone's wait, with a second of margin for the hand-over.
        public func isFresh(now: Date = .now) -> Bool {
            now.timeIntervalSince(requestedAt) < Double(PhoneWatchLink.watchStartTimeout.components.seconds) - 1
        }
    }

    public private(set) var isReachable = false

    @ObservationIgnored public var onReceiveRecords: ((RecordBatch) -> Void)?
    @ObservationIgnored public var onStartRequest: ((StartRequest) -> Void)?
    /// WatchConnectivity is ready; the first moment anything can be sent.
    @ObservationIgnored public var onActivate: (() -> Void)?
    /// The other device became reachable, or a queued transfer failed: time to resend what matters.
    @ObservationIgnored public var onShouldResend: (() -> Void)?

    @ObservationIgnored private let session: WCSession? = WCSession.isSupported() ? .default : nil
    @ObservationIgnored private var lastSnapshot: Data?
    @ObservationIgnored private lazy var delegate = LinkDelegate(
        onPayload: { [weak self] payload in Task { @MainActor in self?.receive(payload) } },
        onReachability: { [weak self] reachable in Task { @MainActor in self?.reachabilityChanged(reachable) } },
        onActivate: { [weak self] in Task { @MainActor in self?.didActivate() } },
        onTransferFailed: { [weak self] in Task { @MainActor in self?.onShouldResend?() } })

    public init() {}

    public func activate() {
        guard let session, session.activationState != .activated else { return }
        session.delegate = delegate
        session.activate()
    }

    private func reachabilityChanged(_ reachable: Bool) {
        let becameReachable = reachable && !isReachable
        isReachable = reachable
        if becameReachable { onShouldResend?() }
    }

    private func didActivate() {
        #if os(watchOS)
        receiveLatestContext()
        #endif
        onActivate?()
    }

    #if os(iOS)
    /// A paired Watch with OnlyWorkout installed.
    public var canUseWatch: Bool {
        guard let session, session.activationState == .activated else { return false }
        return session.isPaired && session.isWatchAppInstalled
    }

    /// Publishes the plan to the Watch, replacing any earlier snapshot.
    public func publish(_ snapshot: RecordBatch, start: StartRequest? = nil) {
        guard let session, session.activationState == .activated, session.isPaired,
            let data = try? JSONEncoder().encode(snapshot)
        else { return }
        lastSnapshot = data
        var context: [String: Any] = [LinkPayload.recordsKey: data]
        if let start, let startData = try? JSONEncoder().encode(start) { context[LinkPayload.startKey] = startData }
        try? session.updateApplicationContext(context)
    }

    /// Asks the Watch to start a Workout (read by the Watch when `startWatchApp` launches it).
    public func requestStart(of workoutID: UUID, with snapshot: RecordBatch) {
        publish(snapshot, start: StartRequest(workoutID: workoutID, requestedAt: .now))
    }
    #endif

    #if os(watchOS)
    /// Sends records (finished Sessions, answered suggestions) to the iPhone: immediately if it's reachable,
    /// and always queued as well so they arrive even if the iPhone is away for hours. Duplicates merge away.
    public func send(_ batch: RecordBatch) {
        guard let session, session.activationState == .activated, let data = try? JSONEncoder().encode(batch) else {
            return
        }
        let payload = [LinkPayload.recordsKey: data]
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
        session.transferUserInfo(payload)
    }

    /// The most recent context from the iPhone, e.g. to pick up a start request at launch.
    public func receiveLatestContext() {
        guard let session else { return }
        receive(LinkPayload(session.receivedApplicationContext))
    }
    #endif

    private func receive(_ payload: LinkPayload) {
        if let data = payload.records, let batch = try? JSONDecoder().decode(RecordBatch.self, from: data) {
            onReceiveRecords?(batch)
        }
        if let data = payload.start, let request = try? JSONDecoder().decode(StartRequest.self, from: data) {
            onStartRequest?(request)
        }
    }
}

/// The two values OnlyWorkout puts in WatchConnectivity dictionaries, extracted so they can cross actors.
private struct LinkPayload: Sendable {
    static let recordsKey = "records"
    static let startKey = "start"

    var records: Data?
    var start: Data?

    init(_ dictionary: [String: Any]) {
        records = dictionary[Self.recordsKey] as? Data
        start = dictionary[Self.startKey] as? Data
    }
}

/// WatchConnectivity callbacks arrive on a background queue; forward the plain payloads.
private final class LinkDelegate: NSObject, WCSessionDelegate, Sendable {
    let onPayload: @Sendable (LinkPayload) -> Void
    let onReachability: @Sendable (Bool) -> Void
    let onActivate: @Sendable () -> Void
    let onTransferFailed: @Sendable () -> Void

    init(
        onPayload: @escaping @Sendable (LinkPayload) -> Void, onReachability: @escaping @Sendable (Bool) -> Void,
        onActivate: @escaping @Sendable () -> Void, onTransferFailed: @escaping @Sendable () -> Void
    ) {
        self.onPayload = onPayload
        self.onReachability = onReachability
        self.onActivate = onActivate
        self.onTransferFailed = onTransferFailed
    }

    /// Queued transfers can fail (e.g. time out while the iPhone is off); they are not retried by the system.
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: (any Error)?) {
        if error != nil { onTransferFailed() }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        onReachability(session.isReachable)
        if activationState == .activated { onActivate() }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        onReachability(session.isReachable)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        onPayload(LinkPayload(applicationContext))
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        onPayload(LinkPayload(message))
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        onPayload(LinkPayload(userInfo))
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
#endif
