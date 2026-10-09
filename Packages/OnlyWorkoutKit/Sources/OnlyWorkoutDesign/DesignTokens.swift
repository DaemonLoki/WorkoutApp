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
        public static let xxl: Double = 48
    }

    public enum Radius {
        public static let card: Double = 24
        public static let control: Double = 16
        /// The miniature app screens in the Welcome Tour.
        public static let demoScreen: Double = 44
    }

    public enum Size {
        /// Diameter of the Rest countdown ring on iPhone.
        public static let restRing: Double = 240
        public static let restRingLineWidth: Double = 14
        public static let celebrationMark: Double = 120
        public static let minimumTapTarget: Double = 44
        /// Widest a column of onboarding text and buttons gets (large iPhones, iPhone Duo's inner display).
        public static let readableWidth: Double = 560
        /// Watch counterparts of the sizes above.
        public static let watchRestRing: Double = 110
        public static let watchRestRingLineWidth: Double = 9
        public static let watchCelebrationMark: Double = 64
        /// The Step Up plate on the Welcome page.
        public static let welcomeMark: Double = 132
        /// Symbols and icons heading the onboarding setup pages.
        public static let onboardingSymbol: Double = 64
    }

    public enum Motion {
        /// Numbers rolling to a new value (reps, weight, counters).
        public static let valueChange = Animation.snappy(duration: 0.2)
        /// Step Up / Step Down cards entering and leaving: spring without bounce.
        public static let card = Animation.smooth(duration: 0.35)
        /// A collapsed section opening or closing (e.g. Ready to Step Up on Today).
        public static let disclosure = Animation.smooth(duration: 0.25)
        /// The Session-complete celebration: the one place with bounce.
        public static let celebration = Animation.spring(duration: 0.5, bounce: 0.2)
        /// Delay between progress cards appearing on the Summary.
        public static let stagger: Double = 0.06
        /// Cross-fade used instead of movement when Reduce Motion is on.
        public static let reducedMotion = Animation.easeOut(duration: 0.2)
        /// Onboarding content arriving (seen once, so it may take a little longer): spring without bounce.
        public static let entrance = Animation.smooth(duration: 0.5)
        /// Moving between onboarding steps.
        public static let step = Animation.smooth(duration: 0.4)
        /// A Welcome Tour demo plays itself after this many seconds without a tap.
        public static let demoIdle: Double = 2.5
        /// A self-playing Welcome Tour demo: from its fingertip touching down to the tap taking effect.
        public static let demoTapLanding: Double = 0.2
        /// A self-playing Welcome Tour demo: from one logged Set to the next tap.
        public static let demoSetInterval: Double = 1.5
        /// Delay between rows arriving in a Welcome Tour demo; slower than `stagger`, since it explains.
        public static let demoStagger: Double = 0.12
    }
}
