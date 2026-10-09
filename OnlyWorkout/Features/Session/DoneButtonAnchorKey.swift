import SwiftUI

/// Where a Set view's Done button is, so a self-playing Welcome Tour demo can show its tap landing there.
struct DoneButtonAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}
