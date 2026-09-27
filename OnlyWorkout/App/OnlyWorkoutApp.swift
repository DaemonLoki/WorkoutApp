import OnlyWorkoutStore
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
        if isUITesting {
            SampleData.insertStarterWorkout(into: container.mainContext)
        }
        _appModel = State(initialValue: AppModel(log: TrainingLog(context: container.mainContext)))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
        }
        .modelContainer(container)
    }
}
