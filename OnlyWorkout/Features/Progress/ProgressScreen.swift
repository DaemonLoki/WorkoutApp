import OnlyWorkoutCore
import OnlyWorkoutStore
import SwiftData
import SwiftUI

/// Progress per Exercise and the Session history, filtered by time range, Muscle Group and search.
struct ProgressScreen: View {
    enum Mode: Hashable {
        case exercises, sessions
    }

    @Query(Queries.liveSessionExercises) private var entries: [SessionExercise]
    @Query(Queries.allExercises) private var exercises: [Exercise]
    @Query(Queries.liveSessions) private var sessions: [Session]
    @State private var mode = Mode.exercises
    @State private var range = StatsRange.threeMonths
    @State private var muscleGroup: MuscleGroup?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(selection: $mode) {
                        Text(.exercises).tag(Mode.exercises)
                        Text(.sessions).tag(Mode.sessions)
                    } label: {
                        Text(.view)
                    }
                    Picker(selection: $range) {
                        ForEach(StatsRange.allCases) { Text($0.title).tag($0) }
                    } label: {
                        Text(.timeRange)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                switch mode {
                case .exercises: exerciseRows
                case .sessions: sessionRows
                }
            }
            .searchable(text: $searchText)
            .navigationTitle(Text(.tabProgress))
            .navigationDestination(for: ExerciseProgressRoute.self) { route in
                ExerciseProgressView(route: route, range: range)
            }
            .navigationDestination(for: Session.self) { session in
                SessionDetailView(session: session)
            }
            .toolbar {
                Menu {
                    Picker(selection: $muscleGroup) {
                        Text(.allMuscleGroups).tag(MuscleGroup?.none)
                        ForEach(MuscleGroup.allCases) { Text($0.title).tag(MuscleGroup?.some($0)) }
                    } label: {
                        Text(.muscleGroup)
                    }
                } label: {
                    Label(
                        .muscleGroup,
                        systemImage: muscleGroup == nil
                            ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
            }
        }
    }

    // MARK: - Exercises

    @ViewBuilder
    private var exerciseRows: some View {
        let rows = exerciseProgress
        if rows.isEmpty {
            ContentUnavailableView(
                .noProgressTitle, systemImage: "chart.line.uptrend.xyaxis", description: Text(.noProgressMessage))
        }
        ForEach(rows, id: \.route) { row in
            NavigationLink(value: row.route) {
                ExerciseProgressRow(name: row.route.name, stats: row.stats)
            }
        }
    }

    private var exerciseProgress: [(route: ExerciseProgressRoute, stats: ExerciseStats, last: Date)] {
        let exercisesByID = Dictionary(exercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let grouped = Dictionary(grouping: performedEntries, by: \.exerciseID)
        return grouped.compactMap { exerciseID, entries in
            let exercise = exercisesByID[exerciseID]
            let name = exercise?.name ?? entries.first?.exerciseName ?? ""
            if let muscleGroup, exercise?.muscleGroups.contains(muscleGroup) != true { return nil }
            if !searchText.isEmpty, !name.localizedStandardContains(searchText) { return nil }
            let stats = ExerciseStats(results: entries.map(\.result))
            return (
                ExerciseProgressRoute(exerciseID: exerciseID, name: name), stats,
                stats.points.last?.date ?? .distantPast
            )
        }
        .sorted { $0.last > $1.last }
    }

    private var performedEntries: [SessionExercise] {
        entries.filter { entry in
            guard let session = entry.session, session.deletedAt == nil, session.endedAt != nil else { return false }
            return entry.status != .skipped && !entry.orderedSets.isEmpty
                && range.contains(session.startedAt, now: .now)
        }
    }

    // MARK: - Sessions

    @ViewBuilder
    private var sessionRows: some View {
        let filtered = filteredSessions
        if filtered.isEmpty {
            ContentUnavailableView(.noSessionsTitle, systemImage: "calendar", description: Text(.noSessionsMessage))
        }
        ForEach(filtered) { session in
            NavigationLink(value: session) {
                SessionRow(session: session)
            }
        }
    }

    private var filteredSessions: [Session] {
        let exercisesByID = Dictionary(exercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return sessions.filter { session in
            guard session.endedAt != nil, range.contains(session.startedAt, now: .now) else { return false }
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

/// Navigation value for one Exercise's progress.
struct ExerciseProgressRoute: Hashable {
    let exerciseID: UUID
    let name: String
}
