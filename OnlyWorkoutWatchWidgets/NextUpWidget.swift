import SwiftUI
import WidgetKit

/// Complication / Smart Stack widget: "Next up: Pull Day"; tapping it starts that Session (README §8).
struct NextUpWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextUp", provider: NextUpProvider()) { entry in
            NextUpWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "onlyworkout://start"))
        }
        .configurationDisplayName(Text(.widgetDisplayName))
        .description(Text(.widgetDescription))
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline, .accessoryCorner])
    }
}

struct NextUpEntry: TimelineEntry {
    let date: Date
    let workoutName: String?
}

struct NextUpProvider: TimelineProvider {
    /// Written by the Watch app whenever the plan or Rotation changes.
    private static let suiteName = "group.com.stefanblos.OnlyWorkout"
    private static let key = "nextUpWorkoutName"

    func placeholder(in context: Context) -> NextUpEntry {
        NextUpEntry(date: .now, workoutName: "Pull Day")
    }

    func getSnapshot(in context: Context, completion: @escaping (NextUpEntry) -> Void) {
        completion(currentEntry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextUpEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry], policy: .never))
    }

    private var currentEntry: NextUpEntry {
        NextUpEntry(date: .now, workoutName: UserDefaults(suiteName: Self.suiteName)?.string(forKey: Self.key))
    }
}

struct NextUpWidgetView: View {
    let entry: NextUpEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular, .accessoryCorner:
            Image(systemName: "dumbbell.fill")
                .font(.title2)
                .widgetAccentable()
                .widgetLabel { Text(name) }
        case .accessoryInline:
            Label {
                Text(name)
            } icon: {
                Image(systemName: "dumbbell.fill")
            }
        default:
            VStack(alignment: .leading) {
                Label {
                    Text(.widgetNextUp)
                } icon: {
                    Image(systemName: "dumbbell.fill")
                }
                .font(.headline)
                .widgetAccentable()
                Text(name)
                    .font(.title3.bold())
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var name: String {
        entry.workoutName ?? String(localized: .widgetNoWorkout)
    }
}
