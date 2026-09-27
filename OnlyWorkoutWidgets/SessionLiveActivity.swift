import ActivityKit
import OnlyWorkoutLiveActivity
import SwiftUI
import WidgetKit

/// Lock Screen and Dynamic Island presentation of a running Session.
struct SessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            LockScreenView(attributes: context.attributes, state: context.state)
                .padding()
                .activitySystemActionForegroundColor(.accentColor)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text(state.exerciseName).font(.headline).lineLimit(1)
                        Text(state.setLabel).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TrailingValue(state: state)
                        .font(.title2.bold())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let next = state.nextUp {
                        Text(next).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
            } compactLeading: {
                Image(systemName: state.restInterval == nil ? "dumbbell.fill" : "timer")
                    .foregroundStyle(Color.accentColor)
            } compactTrailing: {
                if let rest = state.restInterval {
                    Text(timerInterval: rest, countsDown: true)
                        .monospacedDigit()
                        .frame(maxWidth: 44)
                } else {
                    Text(state.shortSetLabel).monospacedDigit()
                }
            } minimal: {
                Image(systemName: state.restInterval == nil ? "dumbbell.fill" : "timer")
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

private struct LockScreenView: View {
    let attributes: SessionActivityAttributes
    let state: SessionActivityAttributes.ContentState

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(attributes.workoutName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(state.exerciseName)
                    .font(.headline)
                Text(
                    state.restInterval == nil ? "\(state.setLabel) · \(state.detail)" : (state.nextUp ?? state.setLabel)
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            Spacer()
            TrailingValue(state: state)
                .font(.system(.title, design: .rounded).bold())
        }
    }
}

/// Rest countdown while resting, otherwise the Set indicator.
private struct TrailingValue: View {
    let state: SessionActivityAttributes.ContentState

    var body: some View {
        Group {
            if let rest = state.restInterval {
                Text(timerInterval: rest, countsDown: true)
            } else {
                Text(state.shortSetLabel)
            }
        }
        .monospacedDigit()
        .foregroundStyle(Color.accentColor)
        .multilineTextAlignment(.trailing)
    }
}
