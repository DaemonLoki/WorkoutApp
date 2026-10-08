import Foundation

/// A finished Session as Strava's "Strength Training (Limited)" upload file, posted to
/// `POST /uploads` with `data_type=json` (docs/research/strava-api.md §1). Health data never goes in.
public struct StravaUpload: Equatable, Sendable {
    /// One Set with the Strava exercise type of its Exercise, if it has one.
    public struct PerformedSet: Equatable, Sendable {
        public var exerciseType: String?
        public var set: LoggedSet
        public var completedAt: Date

        public init(exerciseType: String?, set: LoggedSet, completedAt: Date) {
            self.exerciseType = exerciseType
            self.set = set
            self.completedAt = completedAt
        }
    }

    public let startedAt: Date
    public let endedAt: Date
    /// Seconds east of UTC where the Session took place; Strava uses it for display only.
    public let utcOffset: Int
    public let creator: String
    /// Each exercise type's Sets together in performed order, types in the order they were first performed:
    /// Strava lists Sets as they come, so a Superset stays readable. Only types Strava knows.
    public let sets: [PerformedSet]

    /// `nil` when no Set is left to send; Strava needs at least one.
    public init?(startedAt: Date, endedAt: Date, utcOffset: Int, creator: String, sets: [PerformedSet]) {
        let sets = sets.filter { $0.exerciseType.map(StravaExerciseGroup.isKnown) ?? false }
        guard !sets.isEmpty else { return nil }
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.utcOffset = utcOffset
        self.creator = creator
        let performed = sets.sorted { $0.completedAt < $1.completedAt }
        let typeOrder = performed.compactMap(\.exerciseType).reduce(into: [String]()) { order, type in
            if !order.contains(type) { order.append(type) }
        }
        self.sets = typeOrder.flatMap { type in performed.filter { $0.exerciseType == type } }
    }

    /// The JSON file Strava takes.
    public func file() throws -> Data {
        try JSONEncoder().encode(
            File(
                startTime: startedAt.formatted(.iso8601), utcOffset: utcOffset,
                elapsedTime: Int(endedAt.timeIntervalSince(startedAt).rounded()), creator: .init(name: creator),
                sets: sets.compactMap { performed in
                    performed.exerciseType.map {
                        // A bodyweight Set without Added Weight has no weight to report.
                        File.Set(
                            exerciseType: $0, repetitions: performed.set.reps,
                            weight: performed.set.weight > 0 ? performed.set.weight : nil)
                    }
                }))
    }

    private struct File: Encodable {
        struct Creator: Encodable {
            var name: String
        }

        struct Set: Encodable {
            var exerciseType: String
            var repetitions: Int
            var weight: Double?

            enum CodingKeys: String, CodingKey {
                case exerciseType = "exercise_type", repetitions, weight
            }
        }

        var version = "1.0"
        var startTime: String
        var utcOffset: Int
        var elapsedTime: Int
        var creator: Creator
        var sets: [Set]

        enum CodingKeys: String, CodingKey {
            case version, startTime = "start_time", utcOffset = "utc_offset", elapsedTime = "elapsed_time", creator,
                sets
        }
    }
}
