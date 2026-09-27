import SwiftUI

/// Countdown ring for Rest: drains linearly (constant motion) and shows the time left in the middle.
public struct RestRing: View {
    private let interval: ClosedRange<Date>
    private let lineWidth: Double

    public init(interval: ClosedRange<Date>, lineWidth: Double = DesignTokens.Size.restRingLineWidth) {
        self.interval = interval
        self.lineWidth = lineWidth
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: remainingFraction(at: context.date))
                    .stroke(.tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(timerInterval: interval, countsDown: true)
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func remainingFraction(at date: Date) -> Double {
        let total = interval.upperBound.timeIntervalSince(interval.lowerBound)
        guard total > 0 else { return 0 }
        return min(1, max(0, interval.upperBound.timeIntervalSince(date) / total))
    }
}
