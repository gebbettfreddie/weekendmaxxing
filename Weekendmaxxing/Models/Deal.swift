import Foundation

/// A flagged "super cheap" fare: a destination whose price is well below its
/// typical fare and within the user's budget. Persisted for the Alerts tab and
/// carried (by `id`) in notification payloads.
struct Deal: Identifiable, Hashable, Codable {
    var cityCode: String
    var cityName: String
    var country: String
    var countryCode: String
    var price: Price
    /// The typical fare this deal is compared against.
    var baseline: Double
    var weekend: WeekendWindow
    var foundAt: Date

    /// Stable identity per route + weekend (used for dedupe and notifications).
    var id: String { "\(cityCode)-\(weekend.id)" }

    /// Fraction below the typical price, e.g. 0.47 for 47% off.
    var savings: Double {
        guard baseline > 0 else { return 0 }
        return max(0, 1 - price.amount / baseline)
    }

    var savingsPercent: Int { Int((savings * 100).rounded()) }
}

extension Deal {
    init(destination: Destination, baseline: Double, foundAt: Date = Date()) {
        self.cityCode = destination.city.code
        self.cityName = destination.city.name
        self.country = destination.city.country
        self.countryCode = destination.city.countryCode
        self.price = destination.price
        self.baseline = baseline
        self.weekend = destination.weekend
        self.foundAt = foundAt
    }

    /// Rebuilds a `Destination` (resolving the catalog city for its photo) so the
    /// deal can be opened in `TripDetailView` from the Alerts tab or a tap.
    var destination: Destination {
        let city = CityCatalog.shared.cityOrPlaceholder(forCode: cityCode)
        return Destination(city: city, price: price, weekend: weekend)
    }

    /// The typical fare as a `Price`, for "usually £X" display.
    var baselinePrice: Price { Price(amount: baseline, currency: price.currency) }
}
