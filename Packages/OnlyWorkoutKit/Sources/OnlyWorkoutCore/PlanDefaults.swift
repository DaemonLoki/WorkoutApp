/// Defaults for a newly added Planned Exercise (README §3).
public enum PlanDefaults {
    public static let targetSets = 3
    public static let targetReps = 10
    public static let restSeconds = 90
    public static let setsRange = 1...10
    public static let repsRange = 1...50
    public static let restRange = 30...300
    public static let restStep = 15
    public static let weightSteps: [Double] = [0.5, 1, 1.25, 2, 2.5, 4, 5, 10]
    /// Extra Rest added by the "+30 s" control.
    public static let restExtension = 30.0
}
