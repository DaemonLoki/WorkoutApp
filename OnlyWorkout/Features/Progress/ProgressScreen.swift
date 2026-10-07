import OnlyWorkoutCore
import OnlyWorkoutStore
import SwiftData
import SwiftUI

/// Progress per Exercise, filtered by time range, Muscle Group and search. Past Sessions live in History.
struct ProgressScreen: View {
    @Environment(AppModel.self) private var appModel
    @Query(Queries.liveSessionExercises) private var entries: [SessionExercise]
    @Query(Queries.allExercises) private var exercises: [Exercise]
    @State private var range = StatsRange.threeMonths
    @State private var muscleGroup: MuscleGroup?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(selection: $range) {
                        ForEach(StatsRange.allCases) { Text($0.title).tag($0) }
                    } label: {
                        Text(.timeRange)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                exerciseRows
            }
            .searchable(text: $searchText)
            .navigationTitle(Text(.tabProgress))
            .navigationDestination(for: ExerciseProgressRoute.self) { route in
                ExerciseProgressView(route: route, range: range)
            }
            .toolbar { MuscleGroupFilter(selection: $muscleGroup) }
        }
    }

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
            let stats = ExerciseStats(results: appModel.log.results(of: entries))
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
}

/// Navigation value for one Exercise's progress.
struct ExerciseProgressRoute: Hashable {
    let exerciseID: UUID
    let name: String
}
