import Foundation

/// Last-write-wins merge shared by Watch ↔ iPhone and iPhone ↔ cloud sync (ADR-0001).
public enum RecordMerger {
    /// The incoming records that should overwrite (or create) local ones.
    /// - Parameter existing: `updatedAt` of the local copy of each record, keyed by id.
    public static func winners<Record: SyncRecord>(incoming: [Record], existing: [UUID: Date]) -> [Record] {
        incoming.filter { record in
            guard let local = existing[record.id] else { return true }
            return record.updatedAt > local
        }
    }
}
