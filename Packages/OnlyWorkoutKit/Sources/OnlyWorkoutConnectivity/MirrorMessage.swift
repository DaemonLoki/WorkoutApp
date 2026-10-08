import Foundation
import OnlyWorkoutCore
import OnlyWorkoutStore

/// What the Watch and iPhone exchange over the mirrored workout session (README §6, "Primary device").
/// The primary device sends its state after every change; the other device sends commands.
public enum MirrorMessage: Codable, Sendable {
    case state(MirrorState)
    case command(MirrorCommand)

    public func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }

    public init?(data: Data) {
        guard let message = try? JSONDecoder().decode(MirrorMessage.self, from: data) else { return nil }
        self = message
    }
}

/// Everything the mirroring device needs to draw the Session.
public struct MirrorState: Codable, Equatable, Sendable {
    public struct ExerciseInfo: Codable, Equatable, Sendable {
        public var weightStep: Double
        public var usesAddedWeight: Bool
    }

    public var sessionID: UUID
    public var workoutName: String
    public var startedAt: Date
    public var engine: SessionEngine
    public var offer: SessionOffer?
    public var summary: SessionSummary?
    public var heartRate: Double?
    public var restEndCount: Int
    public var loggedSetCount: Int
    public var exercises: [UUID: ExerciseInfo]

    @MainActor
    public init(runner: SessionRunner, heartRate: Double?) {
        sessionID = runner.session.id
        workoutName = runner.session.workoutName
        startedAt = runner.session.startedAt
        engine = runner.engine
        offer = runner.offer
        summary = runner.summary
        self.heartRate = heartRate
        restEndCount = runner.restEndCount
        loggedSetCount = runner.loggedSetCount
        exercises = Dictionary(
            uniqueKeysWithValues: runner.engine.exercises.map {
                (
                    $0.id,
                    ExerciseInfo(
                        weightStep: runner.weightStep(for: $0.id), usesAddedWeight: runner.usesAddedWeight(for: $0.id))
                )
            })
    }
}

/// An action taken on the mirroring device, performed by the primary one.
public enum MirrorCommand: Codable, Sendable {
    case completeSet(reps: Int, weight: Double)
    case finishRest
    case extendRest
    case skipSet(UUID)
    case skip(UUID)
    case doLater(UUID)
    case addExtraSet(UUID)
    case editSet(exerciseID: UUID, index: Int, reps: Int, weight: Double)
    case answer(SessionOffer, accept: Bool, change: WeightSuggestion.Change?)
    case finish
}

extension SessionRunner {
    public func perform(_ command: MirrorCommand) {
        switch command {
        case .completeSet(let reps, let weight): completeSet(reps: reps, weight: weight)
        case .finishRest: finishRest()
        case .extendRest: extendRest()
        case .skipSet(let id): skipSet(of: id)
        case .skip(let id): skip(id)
        case .doLater(let id): doLater(id)
        case .addExtraSet(let id): addExtraSet(id)
        case .editSet(let id, let index, let reps, let weight):
            editSet(exerciseID: id, at: index, reps: reps, weight: weight)
        case .answer(let offer, let accept, let change): answer(offer, accept: accept, choosing: change)
        case .finish: finish()
        }
    }
}
