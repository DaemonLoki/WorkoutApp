import Charts
import OnlyWorkoutCore
import OnlyWorkoutDesign
import SwiftUI

/// Name, sparkline, current working weight and change within the range.
struct ExerciseProgressRow: View {
    let name: String
    let stats: ExerciseStats

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.s) {
            VStack(alignment: .leading) {
                Text(name)
                if let latest = stats.points.last {
                    Text(latest.workingWeight.kilograms)
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Chart(stats.points, id: \.date) { point in
                LineMark(x: .value("Date", point.date), y: .value("Weight", point.workingWeight))
                    .interpolationMethod(.monotone)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(width: 72, height: 32)
            .accessibilityHidden(true)
            if let change = stats.weightChange, change != 0 {
                Text(change.kilogramsChange)
                    .font(.subheadline.bold())
                    .monospacedDigit()
                    .foregroundStyle(change > 0 ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
        }
    }
}
