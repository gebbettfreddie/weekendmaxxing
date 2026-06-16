import Foundation
import UserNotifications

/// Wraps local-notification permission and delivery, and routes notification
/// taps back into the app via `onOpenDeal`.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    /// Invoked (on the main actor) with a deal id when its notification is tapped.
    var onOpenDeal: ((String) -> Void)?

    private let center = UNUserNotificationCenter.current()

    func registerAsDelegate() {
        center.delegate = self
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Posts one local notification per deal (caller is responsible for capping count).
    func notify(deals: [Deal]) async {
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        for deal in deals {
            let content = UNMutableNotificationContent()
            content.title = "\(deal.cityName) for \(deal.price.formattedRounded)"
            content.body = "\(deal.savingsPercent)% below the usual fare · \(DateUtil.weekendLabel(deal.weekend))"
            content.sound = .default
            content.threadIdentifier = "deals"
            content.userInfo = ["dealID": deal.id]

            let request = UNNotificationRequest(
                identifier: deal.id,
                content: content,
                trigger: nil // deliver immediately
            )
            try? await center.add(request)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show the banner even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let id = response.notification.request.content.userInfo["dealID"] as? String else { return }
        await MainActor.run { onOpenDeal?(id) }
    }
}
