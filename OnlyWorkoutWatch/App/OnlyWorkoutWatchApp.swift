import OnlyWorkoutStore
import SwiftData
import SwiftUI

@main
struct OnlyWorkoutWatchApp: App {
    @WKApplicationDelegateAdaptor private var appDelegate: WatchAppDelegate
    private let container: ModelContainer
    @State private var model: WatchModel

    init() {
        do {
            container = try StoreContainer.make()
        } catch {
            fatalError("Could not open the OnlyWorkout store: \(error)")
        }
        try? ExerciseCatalog.seed(into: container.mainContext)
        _model = State(initialValue: WatchModel(log: TrainingLog(context: container.mainContext)))
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(model)
                .onAppear { appDelegate.model = model }
                .onOpenURL { url in
                    if url == WatchModel.startNextUpURL { model.startNextUp() }
                }
        }
        .modelContainer(container)
    }
}
