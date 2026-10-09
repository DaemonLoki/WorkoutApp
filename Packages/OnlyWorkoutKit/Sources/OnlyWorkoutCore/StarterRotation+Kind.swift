extension StarterRotation {
    /// The three shapes offered: one Workout, two, or three.
    public enum Kind: String, CaseIterable, Identifiable, Sendable {
        case fullBody, upperLower, pushPullLegs

        public var id: Self { self }

        /// The Focus of each Workout, in Rotation order.
        public var foci: [Focus] {
            switch self {
            case .fullBody: [.fullBody]
            case .upperLower: [.upperBody, .lowerBody]
            case .pushPullLegs: [.push, .pull, .legs]
            }
        }
    }
}
