import Foundation

/// The time-range filter on the Progress screens.
public enum StatsRange: String, CaseIterable, Identifiable, Codable, Sendable {
    case fourWeeks, threeMonths, sixMonths, oneYear, all

    public var id: Self { self }

    /// The earliest date inside the range, or `nil` for `.all`.
    public func startDate(now: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .fourWeeks: calendar.date(byAdding: .weekOfYear, value: -4, to: now)
        case .threeMonths: calendar.date(byAdding: .month, value: -3, to: now)
        case .sixMonths: calendar.date(byAdding: .month, value: -6, to: now)
        case .oneYear: calendar.date(byAdding: .year, value: -1, to: now)
        case .all: nil
        }
    }

    public func contains(_ date: Date, now: Date, calendar: Calendar = .current) -> Bool {
        guard let start = startDate(now: now, calendar: calendar) else { return true }
        return date >= start
    }
}
