import Foundation
import OnlyWorkoutCore
import SwiftData

/// One performance of a Workout; keeps its own copy of names and Targets (ADR-0005).
@Model
public final class Session {
    public enum Device: String, Codable, Sendable {
        case phone, watch
    }

    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    /// The `updatedAt` the cloud is known to have; local only, never synced.
    public var syncedUpdatedAt: Date?

    public var workoutID: UUID?
    public var workoutName: String
    public var startedAt: Date
    /// `nil` while in progress.
    public var endedAt: Date?
    public var recordedOnRaw: String
    /// Local only; never synced (README §11).
    public var healthWorkoutID: UUID?
    /// When the Session reached Strava; synced, so a reinstall never uploads it again.
    public var stravaUploadedAt: Date?
    /// Strava's activity, for "View on Strava". Strava Data: local only and kept no longer than
    /// `stravaActivityIDLifetime` (Strava API Policy §6.2).
    public var stravaActivityID: Int64?
    public static let stravaActivityIDLifetime: TimeInterval = 7 * 86_400
    /// Encoded `SessionEngine` while in progress, so the Session can resume after termination.
    public var engineState: Data?

    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    public var exercises: [SessionExercise] = []

    public init(
        id: UUID = UUID(), workoutID: UUID?, workoutName: String, startedAt: Date, recordedOn: Device = .phone
    ) {
        self.id = id
        self.createdAt = startedAt
        self.updatedAt = startedAt
        self.workoutID = workoutID
        self.workoutName = workoutName
        self.startedAt = startedAt
        self.recordedOnRaw = recordedOn.rawValue
    }

    public var recordedOn: Device {
        Device(rawValue: recordedOnRaw) ?? .phone
    }

    public var isInProgress: Bool {
        endedAt == nil
    }

    public var orderedExercises: [SessionExercise] {
        exercises.sorted { $0.position < $1.position }
    }

    public var allSets: [SetEntry] {
        orderedExercises.flatMap(\.orderedSets)
    }

    public var duration: TimeInterval? {
        endedAt.map { $0.timeIntervalSince(startedAt) }
    }

    /// Σ reps × weight over every Set.
    public var totalVolume: Double {
        allSets.reduce(0) { $0 + Double($1.reps) * $1.weight }
    }
}
