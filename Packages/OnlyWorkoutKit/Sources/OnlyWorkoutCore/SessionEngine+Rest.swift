import Foundation

extension SessionEngine {
    /// A running Rest period.
    public struct Rest: Hashable, Codable, Sendable {
        public var startedAt: Date
        public var duration: TimeInterval

        public var endsAt: Date { startedAt.addingTimeInterval(duration) }
    }
}
