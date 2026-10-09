/// A ready-made Rotation offered to a new user for one Equipment Access (README §7 Onboarding).
/// Exercises are named by catalog key; once added, its Workouts are ordinary Workouts.
public struct StarterRotation: Hashable, Sendable {
    public let kind: Kind
    public let equipmentAccess: EquipmentAccess
    /// In Rotation order.
    public let workouts: [Workout]

    public init(kind: Kind, equipmentAccess: EquipmentAccess, workouts: [Workout]) {
        self.kind = kind
        self.equipmentAccess = equipmentAccess
        self.workouts = workouts
    }

    /// The Starter Rotation of this kind for this Equipment Access.
    public static func make(_ kind: Kind, for access: EquipmentAccess) -> StarterRotation {
        StarterRotation(
            kind: kind, equipmentAccess: access,
            workouts: kind.foci.map { Workout(focus: $0, plannedExercises: plannedExercises(for: $0, access)) })
    }
}
