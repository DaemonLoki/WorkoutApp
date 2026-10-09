/// The parts of first-launch onboarding, in order (README §7 Onboarding). Steps that don't apply are skipped.
enum OnboardingStep: Int, CaseIterable, Comparable {
    /// Welcome and the four tour pages; swipeable, with Skip.
    case tour
    /// Sign in with Apple to restore, or Start Fresh. Only with Cloud Sync.
    case restore
    /// Choose a Starter Rotation and Equipment Access, or Build My Own. Only while there are no Workouts.
    case starterRotation
    /// Weights for the chosen Starter Rotation. Only when it has Exercises that use weight.
    case startingWeights
    /// One Continue to Apple Health's sheet. Only when Apple Health would ask.
    case health
    /// One Continue to the notification alert. Only when nobody has answered it yet.
    case restAlerts
    /// The plan that's ready, then Today. Not after Build My Own, which ends in the Workout editor.
    case ready

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}
