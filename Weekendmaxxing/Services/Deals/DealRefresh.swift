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

    /// Ask iOS to run the task again later (no-op while alerts are disabled).
    static func schedule() {
        guard DealStore.shared.alertsEnabled else { return }
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

        let monitor = DealMonitor(service: service)
        let work = Task {
            await monitor.runAndNotify()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            work.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
