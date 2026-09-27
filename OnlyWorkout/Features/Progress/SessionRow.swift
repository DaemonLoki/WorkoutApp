import OnlyWorkoutDesign
import OnlyWorkoutStore
import SwiftUI

struct SessionRow: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading) {
            Text(session.workoutName)
            Text(
                .sessionRowDetail(
                    session.startedAt.formatted(.dateTime.weekday().day().month()),
                    Duration.seconds(session.duration ?? 0).formatted(
                        .units(allowed: [.hours, .minutes], width: .abbreviated)),
                    String(localized: .setCount(session.allSets.count)))
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}
