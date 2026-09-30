import UIKit

extension UIApplication {
    /// Waits (up to `timeout`) until no view controller is presented over the key window's root,
    /// e.g. a system permission sheet that is still animating away. Presenting before that fails silently.
    func waitUntilNothingIsPresented(timeout: Duration = .seconds(2)) async {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while clock.now < deadline {
            let root = connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController
            if root?.presentedViewController == nil { return }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
}
