import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// The Watch's Set screen (`OnlyWorkoutWatch/.../WatchSetView`) drawn for the Welcome Tour on iPhone, which can't
/// compile the original (it turns reps with the Digital Crown). Keep its layout in step with that view.
struct WatchSetReplica: View {
    let exerciseName: String
    let setNumber: Int
    let totalSets: Int
    let reps: Int
    let weight: Double
    let heartRate: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxs) {
            HStack {
                Image(systemName: "forward")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Label {
                    Text(heartRate, format: .number)
                } icon: {
                    Image(systemName: "heart.fill").foregroundStyle(.red)
                }
                .font(.footnote)
                .monospacedDigit()
            }
            Text(verbatim: exerciseName)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(.setProgress(setNumber, totalSets))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: Double(setNumber)))
            BigNumberText(Double(reps), text: "\(reps)", baseSize: 44)
            Text(weight.kilograms)
                .font(.footnote)
                .monospacedDigit()
                .padding(.horizontal, DesignTokens.Spacing.s)
                .padding(.vertical, DesignTokens.Spacing.xxs)
                .background(.fill.secondary, in: .capsule)
            Button(action: onDone) {
                Text(.done).font(.headline).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .anchorPreference(key: DoneButtonAnchorKey.self, value: .bounds) { $0 }
        }
        .padding(.horizontal, DesignTokens.Spacing.s)
        .padding(.vertical, DesignTokens.Spacing.xs)
    }
}
