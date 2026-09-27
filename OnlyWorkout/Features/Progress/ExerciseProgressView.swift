import Charts
import OnlyWorkoutCore
import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

/// Working weight over time with Step Up markers, best Set, volume and every past Set.
struct ExerciseProgressView: View {
    let route: ExerciseProgressRoute
    let range: StatsRange
    @Environment(AppModel.self) private var appModel
    @State private var selectedDate: Date?

    var body: some View {
        let entries = appModel.log.performed(exerciseID: route.exerciseID)
            .filter { range.contains($0.session?.startedAt ?? .distantPast, now: .now) }
        let stats = ExerciseStats(results: entries.map(\.result))

        List {
            Section {
                chart(stats)
                    .frame(height: 220)
                    .padding(.vertical, DesignTokens.Spacing.xs)
            }

            Section {
                if let best = stats.bestSet {
                    LabeledContent {
                        Text(.repsAtWeight(best.reps, best.weight.kilograms)).monospacedDigit()
                    } label: {
                        Text(.bestSet)
                    }
                }
                if stats.totalVolume > 0 {
                    LabeledContent {
                        Text(stats.totalVolume.kilograms).monospacedDigit()
                    } label: {
                        Text(.totalVolume)
                    }
                } else {
                    LabeledContent {
                        Text(stats.totalReps, format: .number)
                    } label: {
                        Text(.totalReps)
                    }
                }
                if let change = stats.weightChange {
                    LabeledContent {
                        Text(change.kilogramsChange).monospacedDigit()
                    } label: {
                        Text(.weightChange)
                    }
                }
            }

            ForEach(entries.reversed()) { entry in
                Section {
                    ForEach(entry.orderedSets) { set in
                        LabeledContent {
                            Text(.repsAtWeight(set.reps, set.weight.kilograms)).monospacedDigit()
                        } label: {
                            Text(set.isExtra ? .extraSet : .setNumber(set.number))
                        }
                    }
                } header: {
                    Text(entry.session?.startedAt ?? entry.createdAt, format: .dateTime.weekday().day().month().year())
                }
            }
        }
        .navigationTitle(route.name)
    }

    private func chart(_ stats: ExerciseStats) -> some View {
        Chart {
            ForEach(stats.points, id: \.date) { point in
                LineMark(x: .value("Date", point.date), y: .value("Weight", point.workingWeight))
                    .interpolationMethod(.monotone)
                PointMark(x: .value("Date", point.date), y: .value("Weight", point.workingWeight))
                    .symbolSize(point.isStepUp ? 90 : 30)
                    .foregroundStyle(point.isStepUp ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
            if let selectedDate, let point = nearest(to: selectedDate, in: stats.points) {
                RuleMark(x: .value("Date", point.date))
                    .foregroundStyle(.quaternary)
                    .annotation(position: .top, overflowResolution: .init(x: .fit, y: .disabled)) {
                        Text(point.workingWeight.kilograms)
                            .font(.caption.bold())
                            .monospacedDigit()
                    }
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartYScale(domain: yDomain(for: stats.points))
        .accessibilityLabel(Text(.weightOverTime))
    }

    /// Pads the weight range so a single Session or a flat line still gets readable axes.
    private func yDomain(for points: [ExerciseStats.Point]) -> ClosedRange<Double> {
        let weights = points.map(\.workingWeight)
        guard let low = weights.min(), let high = weights.max() else { return 0...10 }
        let padding = max(2.5, (high - low) * 0.2)
        return max(0, low - padding)...(high + padding)
    }

    private func nearest(to date: Date, in points: [ExerciseStats.Point]) -> ExerciseStats.Point? {
        points.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }
}
