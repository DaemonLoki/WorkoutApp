import OnlyWorkoutDesign
import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var appModel = appModel
        TabView {
            Tab(.tabToday, systemImage: "figure.strengthtraining.traditional") {
                TodayView()
            }
            Tab(.tabWorkouts, systemImage: "list.bullet.rectangle") {
                WorkoutsView()
            }
            Tab(.tabProgress, systemImage: "chart.line.uptrend.xyaxis") {
                ProgressScreen()
            }
        }
        .fullScreenCover(item: $appModel.activeSession) { active in
            ActiveSessionView(session: active.driver)
        }
        .sheet(item: $appModel.startingOnWatch) { workout in
            StartingOnWatchView { appModel.startOnPhone(workout) }
        }
        .sheet(item: $appModel.healthExplanationFor) { _ in
            HealthExplanationView { appModel.continueAfterHealthExplanation() }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: appModel.appDidBecomeActive()
            case .background: appModel.appDidEnterBackground()
            default: break
            }
        }
    }
}
