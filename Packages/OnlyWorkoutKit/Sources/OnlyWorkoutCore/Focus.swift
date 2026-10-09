/// The kind of a Workout, which says which Muscle Groups it should train.
public enum Focus: String, CaseIterable, Identifiable, Codable, Sendable {
    case push, pull, legs, upperBody, lowerBody, fullBody, arms, core

    public var id: Self { self }
}
