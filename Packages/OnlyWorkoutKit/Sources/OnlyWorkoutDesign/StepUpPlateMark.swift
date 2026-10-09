import SwiftUI

/// The app icon's Step Up plate (design/icon/a-step-up-plate): a white weight plate with a chevron on the accent
/// orange. On the Welcome page it builds itself once: the tile arrives, the plate draws round, the chevron steps up.
/// With Reduce Motion it fades in complete.
public struct StepUpPlateMark: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsTile = false
    @State private var plateProgress = 0.0
    @State private var showsChevron = false
    private let size: Double
    private let animates: Bool

    /// - Parameter animates: `false` shows the finished mark right away.
    public init(size: Double = DesignTokens.Size.welcomeMark, animates: Bool = true) {
        self.size = size
        self.animates = animates
    }

    public var body: some View {
        // Proportions of the 1024 pt icon artwork.
        let unit = size / 1024
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .fill(Color.accentColor.gradient)
                .shadow(color: .accentColor.opacity(0.35), radius: size * 0.18, y: size * 0.08)
            Circle()
                .trim(from: 0, to: plateProgress)
                .stroke(.white, style: StrokeStyle(lineWidth: 104 * unit, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 608 * unit, height: 608 * unit)
            Chevron()
                .stroke(.white, style: StrokeStyle(lineWidth: 96 * unit, lineCap: .round, lineJoin: .round))
                .frame(width: 248 * unit, height: 124 * unit)
                .offset(y: (504 - 512) * unit + (showsChevron ? 0 : 60 * unit))
                .opacity(showsChevron ? 1 : 0)
        }
        .frame(width: size, height: size)
        .scaleEffect(showsTile ? 1 : 0.9)
        .opacity(showsTile ? 1 : 0)
        .accessibilityHidden(true)
        .task {
            guard animates, !reduceMotion else {
                withAnimation(animates ? DesignTokens.Motion.reducedMotion : nil) {
                    showsTile = true
                    plateProgress = 1
                    showsChevron = true
                }
                return
            }
            withAnimation(DesignTokens.Motion.entrance) { showsTile = true }
            try? await Task.sleep(for: .seconds(0.15))
            withAnimation(.easeOut(duration: 0.7)) { plateProgress = 1 }
            try? await Task.sleep(for: .seconds(0.55))
            withAnimation(DesignTokens.Motion.celebration) { showsChevron = true }
        }
    }
}

/// The Step Up chevron: an upward "^" filling its frame.
private struct Chevron: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
    }
}

#Preview {
    StepUpPlateMark()
}
