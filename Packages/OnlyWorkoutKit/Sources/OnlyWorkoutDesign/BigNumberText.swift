import SwiftUI

/// A large, rounded, fixed-width number that rolls when it changes and scales with Dynamic Type.
public struct BigNumberText: View {
    private let text: String
    private let value: Double
    @ScaledMetric(relativeTo: .largeTitle) private var size: Double = 72

    public init(_ value: Double, text: String, baseSize: Double = 72) {
        self.value = value
        self.text = text
        _size = ScaledMetric(wrappedValue: baseSize, relativeTo: .largeTitle)
    }

    public var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText(value: value))
            .animation(DesignTokens.Motion.valueChange, value: value)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}
