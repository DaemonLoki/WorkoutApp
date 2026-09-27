/// The fixed list of body regions an Exercise can train.
public enum MuscleGroup: String, CaseIterable, Identifiable, Codable, Sendable {
    case chest, lats, upperBack, lowerBack, traps, shoulders, biceps, triceps, forearms
    case abs, obliques, glutes, quads, hamstrings, adductors, calves

    public var id: Self { self }
}
