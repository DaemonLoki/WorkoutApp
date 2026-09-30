import SwiftUI

struct WatchRootView: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        if let runner = model.runner {
            WatchSessionView(runner: runner)
        } else {
            WatchHomeView()
        }
    }
}
