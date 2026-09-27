import Foundation
import UserNotifications

/// Alerts when Rest ends while the app is in the background (README §7).
final class RestNotifier {
    private static let identifier = "rest-end"
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() {
        Task { _ = try? await center.requestAuthorization(options: [.alert, .sound]) }
    }

    func schedule(at date: Date, next: String?) {
        cancel()
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = String(localized: .restOverTitle)
        content.body = next ?? ""
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger))
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
    }
}
