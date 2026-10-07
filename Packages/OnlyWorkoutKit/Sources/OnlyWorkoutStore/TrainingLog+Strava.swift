import Foundation
import OnlyWorkoutCore
import SwiftData

/// Uploading finished Sessions to Strava (README §12).
extension TrainingLog {
    /// Finished, live Sessions not uploaded yet that ended at or after `date`, oldest first.
    public func sessionsAwaitingStravaUpload(finishedSince date: Date) -> [Session] {
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { session in
                session.deletedAt == nil && session.stravaUploadedAt == nil
                    && session.endedAt.flatMap { $0 >= date } == true
            },
            sortBy: [SortDescriptor(\.startedAt)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// The Session as Strava's upload file; `nil` while in progress or when no Set has a Strava type.
    public func stravaUpload(of session: Session, creator: String, timeZone: TimeZone) -> StravaUpload? {
        guard let endedAt = session.endedAt else { return nil }
        let sets = session.orderedExercises.flatMap { entry in
            let type = exercise(id: entry.exerciseID)?.uploadedStravaType
            return entry.orderedSets.map {
                StravaUpload.PerformedSet(exerciseType: type, set: $0.loggedSet, completedAt: $0.completedAt)
            }
        }
        return StravaUpload(
            startedAt: session.startedAt, endedAt: endedAt, utcOffset: timeZone.secondsFromGMT(for: session.startedAt),
            creator: creator, sets: sets)
    }

    /// Records a finished upload; the mark syncs, the activity ID stays on this iPhone.
    public func markUploadedToStrava(_ session: Session, activityID: Int64, now: Date = .now) {
        session.stravaUploadedAt = now
        session.stravaActivityID = activityID
        session.updatedAt = now
        try? context.save()
    }

    /// Drops activity IDs older than `Session.stravaActivityIDLifetime`; local only, so nothing to sync.
    public func forgetExpiredStravaActivityIDs(now: Date = .now) {
        let cutoff = now.addingTimeInterval(-Session.stravaActivityIDLifetime)
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { session in
                session.stravaActivityID != nil && session.stravaUploadedAt.flatMap { $0 <= cutoff } ?? true
            })
        let expired = (try? context.fetch(descriptor)) ?? []
        guard !expired.isEmpty else { return }
        for session in expired {
            session.stravaActivityID = nil
        }
        try? context.save()
    }

    func exercise(id: UUID) -> Exercise? {
        try? context.fetch(FetchDescriptor<Exercise>(predicate: #Predicate { $0.id == id })).first
    }
}
