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
}
