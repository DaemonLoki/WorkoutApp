/// One of Strava's groups of exercise types (e.g. "Bench Press"); every Set uploaded to Strava
/// carries one type, from which Strava draws its muscle map.
public struct StravaExerciseGroup: Hashable, Sendable {
    public let name: String
    /// Strava's identifiers, e.g. `BARBELL_BENCH_PRESS`.
    public let types: [String]

    public init(name: String, types: [String]) {
        self.name = name
        self.types = types
    }
}

extension StravaExerciseGroup {
    private static let known = Set(all.flatMap(\.types))

    /// Whether Strava accepts `type`; anything else would fail the upload.
    public static func isKnown(_ type: String) -> Bool {
        known.contains(type)
    }

    /// `CABLE_TRICEPS_PUSHDOWN` → "Cable Triceps Pushdown"; Strava's English names, not localized.
    public static func displayName(of type: String) -> String {
        var words = type.split(separator: "_").map { $0.prefix(1) + $0.dropFirst().lowercased() }
        if words.last == "Generic" {
            words.removeLast()
            return words.joined(separator: " ") + " (Generic)"
        }
        return words.joined(separator: " ")
    }
}
