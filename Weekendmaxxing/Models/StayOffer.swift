import Foundation

/// One place to stay for a weekend — a hotel/hostel/apartment/B&B with its
/// nightly price for the trip's nights. Pairs with a `TripOffer` to form a
/// complete weekend package (flights + stay).
struct StayOffer: Hashable, Codable, Identifiable {
    var name: String
    var type: AccommodationType
    var pricePerNight: Price
    var nights: Int
    /// Guest rating out of 10, when the source provides one.
    var rating: Double?
    /// Neighbourhood / area label, when known.
    var area: String?
    /// Where the price came from, so sample/indicative stays aren't shown as
    /// live, bookable quotes. Mirrors `TripOffer.source`.
    var source: OfferSource
    var bookingURL: URL?

    var id: String { "\(name)|\(area ?? "")|\(type.rawValue)" }

    /// Total stay cost across the weekend's nights.
    var total: Price {
        Price(amount: pricePerNight.amount * Double(max(1, nights)), currency: pricePerNight.currency)
    }
}

/// A complete weekend getaway: the cheapest flight offer paired with the
/// cheapest matching stay. `stay` is optional so a destination still works as a
/// flights-only result when no accommodation is available.
struct WeekendPackage {
    var flight: TripOffer
    var stay: StayOffer?

    /// Combined price — flights plus the full stay when present.
    var total: Price {
        let stayAmount = stay?.total.amount ?? 0
        return Price(amount: flight.price.amount + stayAmount, currency: flight.price.currency)
    }

    /// The least confident source across the two legs, used for badging.
    var source: OfferSource {
        guard let stay else { return flight.source }
        // sample < cached < live in confidence; show the weaker of the two.
        let order: [OfferSource] = [.sample, .cached, .live]
        let f = order.firstIndex(of: flight.source) ?? 0
        let s = order.firstIndex(of: stay.source) ?? 0
        return order[min(f, s)]
    }
}
