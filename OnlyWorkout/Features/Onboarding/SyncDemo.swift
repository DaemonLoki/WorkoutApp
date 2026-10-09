import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// Tour page 5: a finished Session reaching Apple Health, Cloud Sync and Strava, one after another. Strava is shown
/// as an option, never as done, since Strava may be full for now (README §12).
struct SyncDemo: View {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownRows = 0

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.l) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Label {
                    Text(Focus.push.workoutName).font(.title3.bold())
                } icon: {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                }
                Text(verbatim: "\(String(localized: .setCount(18))) · \(Self.duration)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .cardBackground()

            Image(systemName: "arrow.down")
                .font(.title3.bold())
                .foregroundStyle(.tertiary)

            VStack(spacing: DesignTokens.Spacing.m) {
                row(0, title: .appleHealth, detail: .tourSyncHealth, isDone: true) { AppleHealthIcon() }
                row(1, title: .cloudSync, detail: .tourSyncCloudSync, isDone: true) {
                    SymbolTile(systemName: "arrow.triangle.2.circlepath")
                }
                row(2, title: .strava, detail: .tourSyncStrava, isDone: false) {
                    SymbolTile(systemName: "arrow.up.right")
                }
            }
            .padding(DesignTokens.Spacing.m)
            .background(.background.secondary, in: .rect(cornerRadius: DesignTokens.Radius.card))
        }
        .dynamicTypeSize(.large)
        .onChange(of: isActive, initial: true) {
            guard isActive, shownRows == 0 else { return }
            Task {
                for count in 1...3 {
                    try? await Task.sleep(for: .seconds(DesignTokens.Motion.demoStagger * 3))
                    withAnimation(reduceMotion ? DesignTokens.Motion.reducedMotion : DesignTokens.Motion.entrance) {
                        shownRows = count
                    }
                }
            }
        }
    }

    /// A sample Session of 52 minutes, e.g. "52 min".
    private static var duration: String {
        Duration.seconds(52 * 60).formatted(.units(allowed: [.minutes], width: .abbreviated))
    }

    private func row(
        _ index: Int, title: LocalizedStringResource, detail: LocalizedStringResource, isDone: Bool,
        @ViewBuilder icon: () -> some View
    ) -> some View {
        let isShown = index < shownRows
        return HStack(spacing: DesignTokens.Spacing.s) {
            icon()
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if isDone {
                Image(systemName: "checkmark")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .symbolEffect(.drawOn, isActive: !isShown)
            }
        }
        .opacity(isShown ? 1 : 0.35)
    }
}

#Preview {
    SyncDemo(isActive: true)
        .padding()
}
