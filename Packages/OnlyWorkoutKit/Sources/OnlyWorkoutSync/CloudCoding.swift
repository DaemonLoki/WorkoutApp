import Foundation
import OnlyWorkoutStore

/// Turns records into the JSON of `sync_push` and back from `sync_pull` (supabase/migrations).
enum CloudCoding {
    static func encodePush(_ batch: RecordBatch) throws -> Data {
        try encoder.encode(CloudTables(batch))
    }

    /// The pulled records and the cursor for the next pull.
    static func decodePull(_ data: Data) throws -> (batch: RecordBatch, cursor: Date?) {
        let tables = try decoder.decode(CloudTables.self, from: data)
        return (tables.batch, tables.cursor)
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .custom { path in CamelCaseKey(snakeCase: path.last!.stringValue) }
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            guard let date = date(fromPostgres: text) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not a timestamp: \(text)")
            }
            return date
        }
        return decoder
    }()

    /// Postgres writes `2026-09-05T18:00:00+00:00`, `…:00.25+00:00` or `…:00.760643+00:00`.
    static func date(fromPostgres text: String) -> Date? {
        let pattern = /^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})(\.\d+)?(Z|([+-])(\d{2}):(\d{2}))$/
        guard let match = text.wholeMatch(of: pattern),
            let wholeSeconds = try? Date(String(match.1) + "Z", strategy: .iso8601)
        else { return nil }
        let fraction = match.2.flatMap { Double("0" + $0) } ?? 0
        var offset: TimeInterval = 0
        if let sign = match.4, let hours = match.5.flatMap({ Int($0) }), let minutes = match.6.flatMap({ Int($0) }) {
            offset = TimeInterval(hours * 3600 + minutes * 60) * (sign == "-" ? -1 : 1)
        }
        return wholeSeconds.addingTimeInterval(fraction - offset)
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(timestamp(date))
        }
        return encoder
    }()

    /// UTC with milliseconds, rounded rather than truncated so a value survives the trip through `Double`.
    static func timestamp(_ date: Date) -> String {
        let milliseconds = Int64((date.timeIntervalSince1970 * 1000).rounded())
        let (seconds, fraction) = milliseconds.quotientAndRemainder(dividingBy: 1000)
        let wholeSeconds = Date(timeIntervalSince1970: TimeInterval(seconds))
        let utc = wholeSeconds.formatted(Date.ISO8601FormatStyle())  // 2026-09-05T18:05:00Z
        return utc.dropLast() + String(format: ".%03lldZ", fraction)
    }
}
