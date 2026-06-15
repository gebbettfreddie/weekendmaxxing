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
