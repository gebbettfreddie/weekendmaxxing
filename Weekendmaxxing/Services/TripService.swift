import Foundation

/// Abstracts the source of flight/trip data so the UI is identical whether it
/// is driven by bundled mock data or the live Travelpayouts API.
protocol TripService: Sendable {
    /// Cheapest weekend destinations reachable from `origin` within an optional budget.
    func cheapestDestinations(
        origin: String,
        maxPrice: Int?,
        weekend: WeekendWindow
    ) async throws -> [Destination]

    /// Concrete priced round-trip offers for a specific route and weekend.
    func offers(
        origin: String,
        destination: String,
        weekend: WeekendWindow,
        adults: Int
    ) async throws -> [TripOffer]
}

extension TripService {
    /// Cheapest destinations across many weekends, keeping only the single
    /// cheapest weekend for each city. Powers the "Best price over the next N
    /// months" discovery option.
    ///
    /// Weekends are scanned in bounded-concurrency batches to keep things quick
    /// without hammering the upstream API. Per-weekend failures are tolerated so
    /// a transient outage (or rate limit) on one weekend still returns the
    /// fares we did manage to fetch; the error is only surfaced when *every*
    /// weekend failed.
    func cheapestDestinations(
        origin: String,
        maxPrice: Int?,
        weekends: [WeekendWindow],
        maxConcurrent: Int = 4
    ) async throws -> [Destination] {
        guard !weekends.isEmpty else { return [] }

        var cheapestByCity: [String: Destination] = [:]
        var lastError: Error?
        var didSucceed = false

        for batch in weekends.chunked(into: maxConcurrent) {
            let results: [Result<[Destination], Error>] = await withTaskGroup(
                of: Result<[Destination], Error>.self
            ) { group in
                for weekend in batch {
                    group.addTask {
                        do {
                            let destinations = try await self.cheapestDestinations(
                                origin: origin,
                                maxPrice: maxPrice,
                                weekend: weekend
                            )
                            return .success(destinations)
                        } catch {
                            return .failure(error)
                        }
                    }
                }
                var collected: [Result<[Destination], Error>] = []
                for await result in group { collected.append(result) }
                return collected
            }

            for result in results {
                switch result {
                case .success(let destinations):
                    didSucceed = true
                    for destination in destinations {
                        if let existing = cheapestByCity[destination.id],
                           existing.price.amount <= destination.price.amount { continue }
                        cheapestByCity[destination.id] = destination
                    }
                case .failure(let error):
                    lastError = error
                }
            }
        }

        if !didSucceed, let lastError {
            throw lastError
        }

        return cheapestByCity.values.sorted { $0.price.amount < $1.price.amount }
    }
}

enum TripServiceError: LocalizedError {
    case notConfigured
    case noResults
    case network(String)
    case decoding(String)
    case server(status: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Live data isn't configured. Add your Travelpayouts token in Config/Secrets.xcconfig."
        case .noResults:
            return "No trips found for this search. Try a different weekend or a higher budget."
        case .network(let message):
            return "Network problem: \(message)"
        case .decoding(let message):
            return "Couldn't read the response: \(message)"
        case .server(let status, let message):
            return "The flight service returned an error (\(status)).\(message.map { " \($0)" } ?? "")"
        }
    }
}
