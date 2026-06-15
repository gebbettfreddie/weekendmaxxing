import Foundation

/// A single flight leg.
struct FlightSegment: Hashable, Codable, Identifiable {
    var origin: String
    var destination: String
    var departure: Date
    var arrival: Date
    var carrierCode: String
    var carrierName: String?
    var flightNumber: String

    var id: String {
        "\(carrierCode)\(flightNumber)-\(origin)\(destination)-\(Int(departure.timeIntervalSince1970))"
    }
}

/// One direction of a trip (outbound or inbound), made of one or more segments.
struct Itinerary: Hashable, Codable {
    var segments: [FlightSegment]
    var durationMinutes: Int
    /// Some data sources (e.g. Travelpayouts) report only a transfer *count*
    /// rather than every connecting segment. When set, this overrides the stop
    /// count that would otherwise be derived from `segments`.
    var stopCountOverride: Int? = nil
}

extension Itinerary {
    var stops: Int { stopCountOverride ?? max(0, segments.count - 1) }
    var departure: Date? { segments.first?.departure }
    var arrival: Date? { segments.last?.arrival }
    var origin: String? { segments.first?.origin }
    var destination: String? { segments.last?.destination }

    var stopsLabel: String {
        switch stops {
        case 0: return "Direct"
        case 1: return "1 stop"
        default: return "\(stops) stops"
        }
    }
}

/// A concrete, priced round-trip offer.
struct TripOffer: Identifiable, Hashable, Codable {
    var id: String
    var price: Price
    var outbound: Itinerary
    var inbound: Itinerary?
    var validatingAirline: String
    var validatingAirlineName: String?
    var destinationCity: City?
    var seatsRemaining: Int?
    /// A ready-made booking deep link supplied by the data source (e.g. a
    /// Travelpayouts/Aviasales affiliate link). When present it is preferred
    /// over the generic route-based fallback in `bookingURL`.
    var deepLinkURL: URL? = nil
}

extension TripOffer {
    var airlineDisplay: String {
        validatingAirlineName ?? validatingAirline
    }

    /// Total round-trip travel time across both directions.
    var totalDurationMinutes: Int {
        outbound.durationMinutes + (inbound?.durationMinutes ?? 0)
    }

    var isDirect: Bool {
        outbound.stops == 0 && (inbound?.stops ?? 0) == 0
    }

    /// A deep link to continue booking. Prefers a source-provided link (e.g. an
    /// Aviasales affiliate URL) and otherwise builds a Skyscanner route link.
    var bookingURL: URL? {
        if let deepLinkURL { return deepLinkURL }
        guard let origin = outbound.origin,
              let destination = outbound.destination,
              let outDate = outbound.departure else { return nil }
        let inDate = inbound?.departure
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyMMdd"
        var path = "transport/flights/\(origin.lowercased())/\(destination.lowercased())/\(fmt.string(from: outDate))"
        if let inDate { path += "/\(fmt.string(from: inDate))" }
        return URL(string: "https://www.skyscanner.net/\(path)/")
    }
}
