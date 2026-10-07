import OnlyWorkoutCore
import OnlyWorkoutStore
import SwiftData
import SwiftUI

/// Every finished Session, newest first and grouped by month, filtered by Muscle Group and search.
struct HistoryView: View {
    @Query(Queries.liveSessions) private var sessions: [Session]
    @Query(Queries.allExercises) private var exercises: [Exercise]
    @State private var muscleGroup: MuscleGroup?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(months, id: \.start) { month in
                    Section {
                        ForEach(month.sessions) { session in
                            NavigationLink(value: session) {
                                SessionRow(session: session)
                            }
                        }
                    } header: {
                        Text(month.start, format: .dateTime.month(.wide).year())
                    }
                }
            }
            .overlay {
                if filteredSessions.isEmpty {
                    if searchText.isEmpty && muscleGroup == nil {
                        ContentUnavailableView(
                            .noSessionsTitle, systemImage: "calendar", description: Text(.noSessionsMessage))
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle(Text(.tabHistory))
            .navigationDestination(for: Session.self) { session in
                SessionDetailView(session: session)
            }
            .toolbar { MuscleGroupFilter(selection: $muscleGroup) }
        }
    }

    /// Filtered Sessions in month sections, newest month first.
    private var months: [(start: Date, sessions: [Session])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSessions) {
            calendar.dateInterval(of: .month, for: $0.startedAt)?.start ?? $0.startedAt
        }
        return grouped.map { (start: $0.key, sessions: $0.value) }.sorted { $0.start > $1.start }
    }

    private var filteredSessions: [Session] {
        let exercisesByID = Dictionary(exercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return sessions.filter { session in
            guard session.endedAt != nil else { return false }
            if let muscleGroup,
                !session.exercises.contains(where: {
                    exercisesByID[$0.exerciseID]?.muscleGroups.contains(muscleGroup) == true
                })
            {
                return false
            }
            if !searchText.isEmpty {
                return session.workoutName.localizedStandardContains(searchText)
                    || session.exercises.contains { $0.exerciseName.localizedStandardContains(searchText) }
            }
            return true
        }
    }
}
