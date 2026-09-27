/// What an Exercise is performed with; decides the default Weight Step.
public enum Equipment: String, CaseIterable, Identifiable, Codable, Sendable {
    case barbell, dumbbell, machine, cable, bodyweight, kettlebell

    public var id: Self { self }

    /// Weight Step suggested for a new Planned Exercise (README §3).
    public var defaultWeightStep: Double {
        switch self {
        case .barbell, .cable, .bodyweight: 2.5
        case .dumbbell: 2
        case .machine: 5
        case .kettlebell: 4
        }
    }

    /// For bodyweight Exercises the weight is Added Weight.
    public var usesAddedWeight: Bool {
        self == .bodyweight
    }
}
