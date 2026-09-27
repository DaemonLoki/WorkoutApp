import Foundation
import Observation
import OnlyWorkoutCore
import OnlyWorkoutStore

/// App-wide state: which Session is running.
@Observable
final class AppModel {
    let log: TrainingLog
    var activeSession: SessionController?

    /// A Session untouched for this long is treated as forgotten and ended (README §6).
    static let abandonedSessionInterval: TimeInterval = 6 * 3600

    init(log: TrainingLog) {
        self.log = log
        guard let session = log.inProgressSession(), var engine = log.restoreEngine(of: session) else { return }
        if Date.now.timeIntervalSince(session.updatedAt) > Self.abandonedSessionInterval {
            engine.end()
            log.finish(session, engine: engine, now: session.updatedAt)
        } else {
            activeSession = SessionController(session: session, engine: engine, log: log)
        }
    }

    func start(_ workout: Workout) {
        guard activeSession == nil else { return }
        let (session, engine) = log.startSession(workout)
        activeSession = SessionController(session: session, engine: engine, log: log)
    }

    func closeSession() {
        activeSession = nil
    }
}
