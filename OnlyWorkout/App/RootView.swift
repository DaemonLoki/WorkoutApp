import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var appModel

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
        .fullScreenCover(item: $appModel.activeSession) { controller in
            ActiveSessionView(controller: controller)
        }
    }
}
