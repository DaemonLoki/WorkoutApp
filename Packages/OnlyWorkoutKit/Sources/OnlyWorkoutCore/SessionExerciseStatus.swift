/// Where a Session Exercise stands within its Session.
public enum SessionExerciseStatus: String, Codable, Sendable, CaseIterable {
    /// Sets are still owed (including when the Session was ended early).
    case pending
    /// Every planned and requested extra Set is logged.
    case done
    case skipped
}
