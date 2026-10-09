/// Which Equipment someone can train with, so ready-made Workouts only use Exercises they can do.
public enum EquipmentAccess: String, CaseIterable, Identifiable, Codable, Sendable {
    /// Everything a gym has.
    case fullGym
    /// Dumbbells and a bench at home; kettlebell Exercises work with one dumbbell.
    case dumbbellsAndBench
    /// No weights; assumes a pull-up bar and a bench or box.
    case bodyweightOnly

    public var id: Self { self }

    public var equipment: Set<Equipment> {
        switch self {
        case .fullGym: Set(Equipment.allCases)
        case .dumbbellsAndBench: [.dumbbell, .kettlebell, .bodyweight]
        case .bodyweightOnly: [.bodyweight]
        }
    }
}
