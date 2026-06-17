import Foundation

/// A queued match notification: a destination that's exactly what the traveller
/// asked for (a saved match now available, or a new preference match).
struct MatchAlert: Identifiable, Sendable {
    let id: String
    let title: String
    let body: String
    let cityCode: String
    let price: Double
}

/// Scans upcoming weekends for trips that exactly fit the traveller, covering
/// both notification scopes:
///   A. destinations the traveller matched (swiped right on) that are now
///      available within budget, and
///   B. brand-new destinations that fit their saved preferences.
/// Mirrors `DealMonitor`; shares the background task in `DealRefresh`.
struct MatchMonitor {
    let service: TripService
    let store: MatchStore
    let origin: String

    init(service: TripService, store: MatchStore = .shared, origin: String = "LON") {
        self.service = service
        self.store = store
        self.origin = origin
    }

    /// Finds all qualifying match alerts, matched destinations first.
    func findAlerts() async -> [MatchAlert] {
        let prefs = PreferencesStore.current()
        let windows = WeekendCalculator.upcomingWeekends(
            months: MatchRules.monthsAhead,
            style: prefs.weekendStyle
        )
        let results = (try? await service.cheapestDestinations(
            origin: origin,
            maxPrice: prefs.maxPriceParam,
            weekends: windows
        )) ?? []
        guard !results.isEmpty else { return [] }

        let matchedCodes = store.matchedCityCodes()
        let cooldown = store.cooldownCityCodes()

        var matchedAlerts: [MatchAlert] = []
        var preferenceAlerts: [MatchAlert] = []

        for destination in results {
            let code = destination.city.code
            let price = destination.price.amount

            // Scope A: a saved match is available within budget.
            if matchedCodes.contains(code) {
                let key = "matched-\(code)"
                if store.shouldNotify(key: key, price: price) {
                    matchedAlerts.append(MatchAlert(
                        id: key,
                        title: "\(destination.name) is available",
                        body: "Your match is on for \(destination.price.formattedRounded) · \(DateUtil.weekendLabel(destination.weekend))",
                        cityCode: code,
                        price: price
                    ))
                }
                continue
            }

            // Scope B: a brand-new destination that fits the preferences.
            guard !cooldown.contains(code),
                  MatchRules.isPreferenceMatch(destination, prefs: prefs) else { continue }
            let key = "pref-\(code)-\(destination.weekend.id)"
            if store.shouldNotify(key: key, price: price) {
                preferenceAlerts.append(MatchAlert(
                    id: key,
                    title: "New match: \(destination.name)",
                    body: "Fits your vibe from \(destination.price.formattedRounded) · \(DateUtil.weekendLabel(destination.weekend))",
                    cityCode: code,
                    price: price
                ))
            }
        }

        // Matched destinations are the strongest signal, so surface them first.
        return matchedAlerts + preferenceAlerts
    }

    /// Background entry point: find matches, fire notifications for the best new
    /// ones, and record them so we don't re-alert.
    func runAndNotify() async {
        let alerts = await findAlerts()
        guard !alerts.isEmpty else { return }

        let toNotify = Array(alerts.prefix(MatchRules.maxNotificationsPerRun))
        await NotificationManager.shared.notify(matches: toNotify)
        for alert in toNotify {
            store.recordNotified(key: alert.id, price: alert.price)
        }
    }
}
