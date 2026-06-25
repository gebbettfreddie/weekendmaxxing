import Foundation

/// Routes each capability to the source that's best at it: Travelpayouts for
/// "cheapest anywhere" discovery, and the live proxy (Google Flights via the
/// cached Cloudflare Worker) for concrete offers on a chosen route.
struct HybridTripService: TripService {
    let discovery: TripService
    let offersProvider: TripService

    func cheapestDestinations(
        origin: String,
        maxPrice: Int?,
        weekend: WeekendWindow
    ) async throws -> [Destination] {
        try await discovery.cheapestDestinations(origin: origin, maxPrice: maxPrice, weekend: weekend)
    }

    func offers(
        origin: String,
        destination: String,
        weekend: WeekendWindow,
        adults: Int
    ) async throws -> [TripOffer] {
        try await offersProvider.offers(
            origin: origin, destination: destination, weekend: weekend, adults: adults
        )
    }

    // Stays are route/destination-specific, like offers, so they take the same
    // live path (proxy → SerpApi google_hotels, with mock fallback).
    func stays(
        city: City,
        weekend: WeekendWindow,
        types: Set<AccommodationType>,
        adults: Int
    ) async throws -> [StayOffer] {
        try await offersProvider.stays(city: city, weekend: weekend, types: types, adults: adults)
    }
}
