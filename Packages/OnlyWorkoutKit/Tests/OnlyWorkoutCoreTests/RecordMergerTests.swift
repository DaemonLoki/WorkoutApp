import Foundation
import Testing

@testable import OnlyWorkoutCore

@Suite("RecordMerger")
struct RecordMergerTests {
    struct Record: SyncRecord, Equatable {
        var id: UUID
        var updatedAt: Date
        var deletedAt: Date?
    }

    let id = UUID()
    let earlier = Date(timeIntervalSince1970: 1_000)
    let later = Date(timeIntervalSince1970: 2_000)

    @Test func aNewerIncomingRecordWinsAndAnOlderOneLoses() {
        let newer = Record(id: id, updatedAt: later)
        let older = Record(id: id, updatedAt: earlier)

        #expect(RecordMerger.winners(incoming: [newer], existing: [id: earlier]) == [newer])
        #expect(RecordMerger.winners(incoming: [older], existing: [id: later]).isEmpty)
    }

    @Test func onATieTheExistingRecordIsKept() {
        let incoming = Record(id: id, updatedAt: earlier)

        #expect(RecordMerger.winners(incoming: [incoming], existing: [id: earlier]).isEmpty)
    }

    @Test func unknownRecordsAndNewerTombstonesAreApplied() {
        let unknown = Record(id: UUID(), updatedAt: earlier)
        let tombstone = Record(id: id, updatedAt: later, deletedAt: later)

        let winners = RecordMerger.winners(incoming: [unknown, tombstone], existing: [id: earlier])

        #expect(winners == [unknown, tombstone])
    }
}
