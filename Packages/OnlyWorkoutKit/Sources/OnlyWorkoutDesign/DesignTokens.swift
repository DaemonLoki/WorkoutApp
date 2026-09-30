import SwiftUI

/// Every spacing, radius, font and motion value the UI uses (README §9). Views never hard-code these.
public enum DesignTokens {
    public enum Spacing {
        public static let xxs: Double = 4
        public static let xs: Double = 8
        public static let s: Double = 12
        public static let m: Double = 16
        public static let l: Double = 24
        public static let xl: Double = 32
    }

    public enum Radius {
        public static let card: Double = 24
        public static let control: Double = 16
    }

    public enum Size {
        /// Diameter of the Rest countdown ring on iPhone.
        public static let restRing: Double = 240
        public static let restRingLineWidth: Double = 14
        public static let celebrationMark: Double = 120
        public static let minimumTapTarget: Double = 44
        /// Watch counterparts of the sizes above.
        public static let watchRestRing: Double = 110
        public static let watchRestRingLineWidth: Double = 9
        public static let watchCelebrationMark: Double = 64
    }

    public enum Motion {
        /// Numbers rolling to a new value (reps, weight, counters).
        public static let valueChange = Animation.snappy(duration: 0.2)
        /// Step Up / Step Down cards entering and leaving: spring without bounce.
        public static let card = Animation.smooth(duration: 0.35)
        /// The Session-complete celebration: the one place with bounce.
        public static let celebration = Animation.spring(duration: 0.5, bounce: 0.2)
        /// Delay between progress cards appearing on the Summary.
        public static let stagger: Double = 0.06
        /// Cross-fade used instead of movement when Reduce Motion is on.
        public static let reducedMotion = Animation.easeOut(duration: 0.2)
    }
}
