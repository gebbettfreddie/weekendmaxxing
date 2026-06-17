import Foundation

/// Scans upcoming weekends for genuinely cheap fares. Shared by the foreground
/// "Check now" action and the background refresh task.
struct DealMonitor {
    let service: TripService
    let store: DealStore
    let origin: String

    init(service: TripService, store: DealStore = .shared, origin: String = "LON") {
        self.service = service
        self.store = store
        self.origin = origin
    }

    /// Finds all qualifying deals across the next few weekends, best (biggest
    /// saving) first, keeping the cheapest fare per route + weekend.
    func findDeals() async -> [Deal] {
        let budget = store.maxBudget
        let weekends = WeekendCalculator.upcomingWeekends(count: DealRules.weekendsToScan)
        var best: [String: Deal] = [:]

        for weekend in weekends {
            let destinations = (try? await service.cheapestDestinations(
                origin: origin,
                maxPrice: Int(budget),
                weekend: weekend
            )) ?? []

            for destination in destinations {
                // Prefer the live typical fare (e.g. Google's average price);
                // fall back to the catalog's static baseline.
                let baseline = destination.typicalPrice ?? destination.city.basePrice
                guard DealRules.isDeal(
                    price: destination.price.amount,
                    baseline: baseline,
                    maxBudget: budget
                ) else { continue }

                let deal = Deal(destination: destination, baseline: baseline)
                if let existing = best[deal.id], existing.price.amount <= deal.price.amount {
                    continue
                }
                best[deal.id] = deal
            }
        }

        return best.values.sorted { $0.savings > $1.savings }
    }

    /// Foreground entry point (Alerts tab "Check now"): refresh the list only.
    @discardableResult
    func refreshDeals() async -> [Deal] {
        let deals = await findDeals()
        store.mergeRecent(deals)
        return deals
    }

    /// Background entry point: find deals, persist them, and fire notifications
    /// for the best new ones.
    func runAndNotify() async {
        let deals = await findDeals()
        store.mergeRecent(deals)

        guard store.alertsEnabled else { return }
        let fresh = deals.filter { store.shouldNotify($0) }
        let toNotify = Array(fresh.prefix(DealRules.maxNotificationsPerRun))
        guard !toNotify.isEmpty else { return }

        await NotificationManager.shared.notify(deals: toNotify)
        store.recordNotified(toNotify)
    }
}
