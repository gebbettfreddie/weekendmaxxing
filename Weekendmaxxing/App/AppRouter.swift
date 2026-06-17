import SwiftUI
import Observation

/// App-level navigation state, used to deep-link from a tapped notification to
/// the relevant destination (a deal on the Alerts tab, or a match on Matches).
@MainActor
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case match, search, alerts, saved
    }

    var selectedTab: Tab = .match
    /// Set when a deal notification is tapped; the Alerts tab pushes it.
    var pendingDealDestination: Destination?
    /// Set when a match notification is tapped; the Matches tab pushes it.
    var pendingMatchDestination: Destination?

    init() {
        // UI-test / screenshot hook: launch with `-initialTab alerts` (etc.).
        switch UserDefaults.standard.string(forKey: "initialTab") {
        case "match": selectedTab = .match
        case "alerts": selectedTab = .alerts
        case "search": selectedTab = .search
        case "saved", "matches": selectedTab = .saved
        default: break
        }
    }

    /// Resolve a tapped deal notification and route to it on the Alerts tab.
    func openDeal(id: String) {
        guard let deal = DealStore.shared.recentDeals().first(where: { $0.id == id }) else { return }
        selectedTab = .alerts
        pendingDealDestination = deal.destination
    }

    /// Resolve a tapped match notification and route to it on the Matches tab.
    func openMatch(cityCode: String) {
        let matched = MatchStore.shared.matchedDestinations()
        if let destination = matched.first(where: { $0.city.code == cityCode }) {
            selectedTab = .saved
            pendingMatchDestination = destination
        } else {
            selectedTab = .match
        }
    }
}
