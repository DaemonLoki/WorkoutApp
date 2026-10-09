import OnlyWorkoutDesign
import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var appModel = appModel
        // The Session cover and sheets sit around both, so a Session started on the Watch shows during onboarding too.
        Group {
            if appModel.showsOnboarding {
                OnboardingView(appModel: appModel)
                    .transition(.opacity)
            } else {
                tabs
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(
            reduceMotion ? DesignTokens.Motion.reducedMotion : DesignTokens.Motion.entrance,
            value: appModel.showsOnboarding
        )
        .fullScreenCover(item: $appModel.activeSession) { active in
            ActiveSessionView(session: active.driver)
        }
        .sheet(item: $appModel.startingOnWatch) { workout in
            StartingOnWatchView { appModel.startOnPhone(workout) }
        }
        .sheet(item: $appModel.healthExplanationFor, onDismiss: appModel.healthExplanationDismissed) { _ in
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

    private var tabs: some View {
        TabView {
            Tab(.tabToday, systemImage: "figure.strengthtraining.traditional") {
                TodayView()
            }
            Tab(.tabWorkouts, systemImage: "list.bullet.rectangle") {
                WorkoutsView()
            }
            Tab(.tabHistory, systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90") {
                HistoryView()
            }
            Tab(.tabProgress, systemImage: "chart.line.uptrend.xyaxis") {
                ProgressScreen()
            }
        }
    }
}
