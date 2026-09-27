#if os(iOS)
    import ActivityKit
    import Foundation

    /// Live Activity shown on the Lock Screen and Dynamic Island while a Session runs (README §7).
    public struct SessionActivityAttributes: ActivityAttributes {
        public struct ContentState: Codable, Hashable, Sendable {
            /// Exercise being performed or rested for, e.g. "Bench Press".
            public var exerciseName: String
            /// e.g. "Set 2 of 3".
            public var setLabel: String
            /// e.g. "2/3", for the compact Dynamic Island.
            public var shortSetLabel: String
            /// e.g. "10 × 60 kg".
            public var detail: String
            /// Set while resting.
            public var restInterval: ClosedRange<Date>?
            /// What comes after the current step, e.g. "Lat Pulldown · 3×12 @ 55 kg".
            public var nextUp: String?

            public init(
                exerciseName: String, setLabel: String, shortSetLabel: String, detail: String,
                restInterval: ClosedRange<Date>?, nextUp: String?
            ) {
                self.exerciseName = exerciseName
                self.setLabel = setLabel
                self.shortSetLabel = shortSetLabel
                self.detail = detail
                self.restInterval = restInterval
                self.nextUp = nextUp
            }
        }

        public var workoutName: String

        public init(workoutName: String) {
            self.workoutName = workoutName
        }
    }
#endif
