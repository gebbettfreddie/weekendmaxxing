import SwiftUI
import Observation

/// App-level navigation state, used to deep-link from a tapped deal notification
/// to the relevant destination on the Alerts tab.
@MainActor
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case discover, search, alerts, saved
    }

    var selectedTab: Tab = .discover
    /// Set when a deal notification is tapped; the Alerts tab pushes it.
    var pendingDealDestination: Destination?

    init() {
        // UI-test / screenshot hook: launch with `-initialTab alerts` (etc.).
        switch UserDefaults.standard.string(forKey: "initialTab") {
        case "alerts": selectedTab = .alerts
        case "search": selectedTab = .search
        case "saved": selectedTab = .saved
        default: break
        }
    }

    /// Resolve a tapped notification's deal id and route to it.
    func openDeal(id: String) {
        guard let deal = DealStore.shared.recentDeals().first(where: { $0.id == id }) else { return }
        selectedTab = .alerts
        pendingDealDestination = deal.destination
    }
}
