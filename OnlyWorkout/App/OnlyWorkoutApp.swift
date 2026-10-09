import OnlyWorkoutStore
import OnlyWorkoutSync
import SwiftData
import SwiftUI

@main
struct OnlyWorkoutApp: App {
    private let container: ModelContainer
    @State private var appModel: AppModel

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")
        do {
            container = try StoreContainer.make(inMemory: isUITesting)
        } catch {
            fatalError("Could not open the OnlyWorkout store: \(error)")
        }
        try? ExerciseCatalog.seed(into: container.mainContext)
        if isUITesting || Self.seedsSampleData {
            SampleData.insertStarterWorkout(into: container.mainContext)
        }
        let log = TrainingLog(context: container.mainContext)
        let services = isUITesting ? nil : CloudServices.configured(log: log)
        // Decided before `AppModel` starts the Watch link, which can deliver Workouts at any moment.
        let showsOnboarding = !isUITesting && (Self.forcesOnboarding || AppModel.needsOnboarding(log: log))
        _appModel = State(
            initialValue: AppModel(
                log: log, services: services, usesHealth: !isUITesting, showsOnboarding: showsOnboarding))
    }

    /// `-onboarding` shows onboarding even when it's done or the store has data, to try it out.
    /// Debug builds only, like `-sampleData`.
    private static var forcesOnboarding: Bool {
        #if DEBUG
            ProcessInfo.processInfo.arguments.contains("-onboarding")
        #else
            false
        #endif
    }

    /// `-sampleData` seeds a starter Workout into the real store, e.g. to try the Watch in the simulator.
    /// Debug builds only: a release build has no hidden switches (App Review guideline 2.3.1).
    private static var seedsSampleData: Bool {
        #if DEBUG
            ProcessInfo.processInfo.arguments.contains("-sampleData")
        #else
            false
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
        }
        .modelContainer(container)
    }
}
