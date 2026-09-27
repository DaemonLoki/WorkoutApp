import Foundation

/// A record that is replicated between devices and the cloud (README §10).
public protocol SyncRecord {
    var id: UUID { get }
    /// Client clock of the last change; decides conflicts.
    var updatedAt: Date { get }
    /// Set instead of deleting, so deletions replicate like any other write.
    var deletedAt: Date? { get }
}
