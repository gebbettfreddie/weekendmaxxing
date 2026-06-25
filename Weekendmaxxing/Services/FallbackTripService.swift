import Foundation

/// Tries the primary service (Travelpayouts) first and transparently falls back
/// to a secondary service (mock) on error or when the primary returns no
/// results. This keeps the UI populated even when a route isn't cached.
struct FallbackTripService: TripService {
    let primary: TripService
    let fallback: TripService

    func cheapestDestinations(
        origin: String,
        maxPrice: Int?,
        weekend: WeekendWindow
    ) async throws -> [Destination] {
        do {
            let results = try await primary.cheapestDestinations(
                origin: origin, maxPrice: maxPrice, weekend: weekend
            )
            if results.isEmpty {
                return try await fallback.cheapestDestinations(
                    origin: origin, maxPrice: maxPrice, weekend: weekend
                )
            }
            return results
        } catch {
            return try await fallback.cheapestDestinations(
                origin: origin, maxPrice: maxPrice, weekend: weekend
            )
        }
    }

    func offers(
        origin: String,
        destination: String,
        weekend: WeekendWindow,
        adults: Int
    ) async throws -> [TripOffer] {
        do {
            let results = try await primary.offers(
                origin: origin, destination: destination, weekend: weekend, adults: adults
            )
            if results.isEmpty {
                return try await fallback.offers(
                    origin: origin, destination: destination, weekend: weekend, adults: adults
                )
            }
            return results
        } catch {
            return try await fallback.offers(
                origin: origin, destination: destination, weekend: weekend, adults: adults
            )
        }
    }

    func stays(
        city: City,
        weekend: WeekendWindow,
        types: Set<AccommodationType>,
        adults: Int
    ) async throws -> [StayOffer] {
        do {
            let results = try await primary.stays(
                city: city, weekend: weekend, types: types, adults: adults
            )
            if results.isEmpty {
                return try await fallback.stays(
                    city: city, weekend: weekend, types: types, adults: adults
                )
            }
            return results
        } catch {
            return try await fallback.stays(
                city: city, weekend: weekend, types: types, adults: adults
            )
        }
    }
}
