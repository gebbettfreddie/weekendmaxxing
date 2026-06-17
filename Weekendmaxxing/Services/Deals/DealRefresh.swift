import Foundation
import BackgroundTasks

/// Registers, schedules, and runs the background deal-check task. Registration
/// must happen at launch (before the app finishes launching); scheduling only
/// happens while alerts are enabled.
enum DealRefresh {
    /// Register the task handler. Call once, early, from the app's `init`.
    static func register(service: TripService) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: DealRules.taskIdentifier,
            using: nil
        ) { task in
            handle(task as! BGAppRefreshTask, service: service)
        }
    }

    /// Whether any background notifications are wanted (deal alerts or
    /// preference-based match alerts).
    static var wantsBackgroundRefresh: Bool {
        DealStore.shared.alertsEnabled || PreferencesStore.current().notificationsEnabled
    }

    /// Ask iOS to run the task again later (no-op while nothing is opted in).
    static func schedule() {
        guard wantsBackgroundRefresh else { return }
        let request = BGAppRefreshTaskRequest(identifier: DealRules.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 8 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    /// Stop future runs (called when the user turns alerts off).
    static func cancel() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: DealRules.taskIdentifier)
    }

    private static func handle(_ task: BGAppRefreshTask, service: TripService) {
        schedule() // chain the next opportunistic run

        let work = Task {
            if DealStore.shared.alertsEnabled {
                await DealMonitor(service: service).runAndNotify()
            }
            if PreferencesStore.current().notificationsEnabled {
                await MatchMonitor(service: service).runAndNotify()
            }
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            work.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
