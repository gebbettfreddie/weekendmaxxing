import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class AlertsViewModel {
    var enabled: Bool {
        didSet {
            guard enabled != oldValue else { return }
            DealStore.shared.alertsEnabled = enabled
            if enabled {
                Task { await enableAlerts() }
            } else {
                DealRefresh.cancel()
            }
        }
    }

    var maxBudget: Double {
        didSet { DealStore.shared.maxBudget = maxBudget }
    }

    var recentDeals: [Deal]
    var isChecking = false
    /// True when alerts are enabled but the OS notification permission is off.
    var permissionDenied = false

    private let service: TripService
    private let store = DealStore.shared

    init(service: TripService) {
        self.service = service
        self.enabled = store.alertsEnabled
        self.maxBudget = store.maxBudget
        self.recentDeals = store.recentDeals()
    }

    var budgetLabel: String {
        CurrencyFormatter.string(amount: maxBudget, currency: "GBP", fractionDigits: 0)
    }

    func onAppear() async {
        recentDeals = store.recentDeals()
        await refreshPermission()
    }

    func refreshPermission() async {
        let status = await NotificationManager.shared.authorizationStatus()
        permissionDenied = enabled && status == .denied
    }

    private func enableAlerts() async {
        let granted = await NotificationManager.shared.requestAuthorization()
        permissionDenied = !granted
        guard granted else { return }
        DealRefresh.schedule()
        await checkNow()
    }

    func checkNow() async {
        guard !isChecking else { return }
        isChecking = true
        let monitor = DealMonitor(service: service)
        if enabled {
            await monitor.runAndNotify()
        } else {
            _ = await monitor.refreshDeals()
        }
        recentDeals = store.recentDeals()
        isChecking = false
    }
}
