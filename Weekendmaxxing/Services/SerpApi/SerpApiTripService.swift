import Foundation

/// Live flight data backed by Google Flights via the Weekendmaxxing proxy
/// (a Cloudflare Worker that fronts SerpApi with a shared cache and holds the
/// API key). Powers both discovery (`/v1/deals`) and route offers (`/v1/offers`).
///
/// Note: a round-trip offers search returns the outbound options with the
/// *total* round-trip price; matching return legs need a second token call, so
/// v1 shows the outbound leg with the round-trip total.
struct SerpApiTripService: TripService {
    private let baseURL: URL
    private let appToken: String
    private let session: URLSession
    private let catalog = CityCatalog.shared

    init(baseURL: URL, appToken: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.appToken = appToken
        self.session = session
    }

    // Discovery stays on Travelpayouts (Google's "deals" feed returns no results
    // for our specific weekend queries). The hybrid never calls this.
    func cheapestDestinations(
        origin: String,
        maxPrice: Int?,
        weekend: WeekendWindow
    ) async throws -> [Destination] {
        throw TripServiceError.noResults
    }

    // MARK: - Offers (google_flights)

    func offers(
        origin: String,
        destination: String,
        weekend: WeekendWindow,
        adults: Int
    ) async throws -> [TripOffer] {
        let items: [URLQueryItem] = [
            .init(name: "departure_id", value: Self.googleID(for: origin)),
            .init(name: "arrival_id", value: Self.googleID(for: destination)),
            .init(name: "outbound_date", value: weekend.departureAPIString),
            .init(name: "return_date", value: weekend.returnAPIString),
            .init(name: "type", value: "1"),
            .init(name: "currency", value: "GBP"),
            .init(name: "hl", value: "en"),
            .init(name: "gl", value: "uk"),
            .init(name: "adults", value: String(max(1, adults)))
        ]

        let response: SerpFlightsResponse = try await get(path: "v1/offers", queryItems: items)
        let outboundFlights = (response.bestFlights ?? []) + (response.otherFlights ?? [])
        if outboundFlights.isEmpty { throw TripServiceError.noResults }

        let city = catalog.cityOrPlaceholder(forCode: destination)

        // Build the outbound-only offers first; the round-trip total price comes
        // back on this first call. Each offer keeps the `departure_token` it was
        // built from so we can fetch its matching return legs below.
        let pending: [(token: String?, offer: TripOffer)] = outboundFlights.enumerated().compactMap { index, flight in
            guard let amount = flight.price, let firstLeg = flight.flights.first else { return nil }

            let outbound = Self.makeItinerary(from: flight, fallbackOrigin: origin, fallbackDestination: destination)
            let (validating, _) = Self.splitFlightNumber(firstLeg.flightNumber)
            let depKey = firstLeg.departureAirport.time ?? "\(index)"

            let offer = TripOffer(
                id: "\(validating)-\(destination.uppercased())-\(depKey)-\(index)",
                price: Price(amount: amount, currency: "GBP"),
                outbound: outbound,
                inbound: nil,
                validatingAirline: validating,
                validatingAirlineName: firstLeg.airline,
                destinationCity: city,
                seatsRemaining: nil,
                source: .live
            )
            return (flight.departureToken, offer)
        }

        // Fetch the return leg for each outbound option in bounded-concurrency
        // batches. Per-offer failures are tolerated: if the return call fails we
        // keep the outbound-only offer rather than dropping it.
        var resolved: [TripOffer] = []
        resolved.reserveCapacity(pending.count)

        for batch in pending.chunked(into: 4) {
            let batchResults: [TripOffer] = await withTaskGroup(of: TripOffer.self) { group in
                for entry in batch {
                    group.addTask {
                        await self.withInbound(
                            offer: entry.offer,
                            departureToken: entry.token,
                            baseItems: items,
                            origin: origin,
                            destination: destination
                        )
                    }
                }
                var collected: [TripOffer] = []
                for await offer in group { collected.append(offer) }
                return collected
            }
            resolved.append(contentsOf: batchResults)
        }

        return resolved.sorted { $0.price.amount < $1.price.amount }
    }

    /// Returns `offer` with its `inbound` populated from a second `/v1/offers`
    /// call keyed by `departureToken`. If the token is missing or the call
    /// fails, the original outbound-only offer is returned unchanged.
    private func withInbound(
        offer: TripOffer,
        departureToken: String?,
        baseItems: [URLQueryItem],
        origin: String,
        destination: String
    ) async -> TripOffer {
        guard let departureToken else { return offer }

        let returnItems = baseItems + [URLQueryItem(name: "departure_token", value: departureToken)]
        do {
            let response: SerpFlightsResponse = try await get(path: "v1/offers", queryItems: returnItems)
            let returnFlights = (response.bestFlights ?? []) + (response.otherFlights ?? [])
            // Return options come back in the same shape; take the cheapest, or
            // the first if no prices are reported, to mirror the outbound leg.
            guard let returnFlight = returnFlights.min(by: {
                ($0.price ?? .greatestFiniteMagnitude) < ($1.price ?? .greatestFiniteMagnitude)
            }) else {
                return offer
            }
            var updated = offer
            // The return leg flies destination -> origin, so swap the fallbacks.
            updated.inbound = Self.makeItinerary(
                from: returnFlight,
                fallbackOrigin: destination,
                fallbackDestination: origin
            )
            return updated
        } catch {
            return offer
        }
    }

    /// Builds an `Itinerary` from a SerpApi `Flight`, applying IATA fallbacks
    /// when a leg omits airport ids.
    private static func makeItinerary(
        from flight: SerpFlightsResponse.Flight,
        fallbackOrigin: String,
        fallbackDestination: String
    ) -> Itinerary {
        let segments = flight.flights.map { leg -> FlightSegment in
            let (code, number) = Self.splitFlightNumber(leg.flightNumber)
            return FlightSegment(
                origin: leg.departureAirport.id ?? fallbackOrigin.uppercased(),
                destination: leg.arrivalAirport.id ?? fallbackDestination.uppercased(),
                departure: Self.parseDateTime(leg.departureAirport.time),
                arrival: Self.parseDateTime(leg.arrivalAirport.time),
                carrierCode: code,
                carrierName: leg.airline,
                flightNumber: number
            )
        }
        let duration = flight.totalDuration ?? segments.reduce(0) { $0 + $1.duration }
        return Itinerary(segments: segments, durationMinutes: duration)
    }

    // MARK: - Networking

    private func get<T: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> T {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw TripServiceError.network("Could not build request URL")
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(appToken, forHTTPHeaderField: "X-App-Token")

        await MainActor.run { APIUsageTracker.shared.record(.proxy) }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw TripServiceError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw TripServiceError.network("Invalid response")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw TripServiceError.server(status: http.statusCode, message: nil)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw TripServiceError.decoding(error.localizedDescription)
        }
    }

    // MARK: - Helpers

    /// Maps app IATA codes to identifiers Google Flights accepts. Google rejects
    /// metropolitan IATA codes (e.g. "LON"), so those map to a city `kgmid` or a
    /// primary airport.
    private static let cityOverrides: [String: String] = [
        "LON": "/m/04jpl", // London (all airports)
        "PAR": "CDG",
        "ROM": "FCO",
        "MIL": "MXP",
        "STO": "ARN"
    ]

    static func googleID(for code: String) -> String {
        let upper = code.uppercased()
        return cityOverrides[upper] ?? upper
    }

    private static func splitFlightNumber(_ value: String?) -> (code: String, number: String) {
        guard let value, !value.isEmpty else { return ("", "") }
        let parts = value.split(separator: " ", maxSplits: 1)
        if parts.count == 2 { return (String(parts[0]), String(parts[1])) }
        return (value, "")
    }

    /// Google Flights times are local wall-clock ("yyyy-MM-dd HH:mm"); like the
    /// rest of the app we keep them verbatim as UTC so displayed times match.
    private static func parseDateTime(_ string: String?) -> Date {
        guard let string else { return Date() }
        return dateTime.date(from: string)
            ?? dateOnly.date(from: String(string.prefix(10)))
            ?? Date()
    }

    private static let dateTime = AppTime.dateFormatter("yyyy-MM-dd HH:mm")
    private static let dateOnly = AppTime.dateFormatter("yyyy-MM-dd")
}

// MARK: - DTOs

/// Decodes the `google_flights` response (via `convertFromSnakeCase`).
private struct SerpFlightsResponse: Decodable {
    let bestFlights: [Flight]?
    let otherFlights: [Flight]?

    struct Flight: Decodable {
        let flights: [Leg]
        let totalDuration: Int?
        let price: Double?
        /// Present on first-call (outbound) options; passing it back in a second
        /// `/v1/offers` call returns the matching return legs.
        let departureToken: String?
        /// Present on return options; identifies a concrete bookable round-trip.
        let bookingToken: String?

        struct Leg: Decodable {
            let departureAirport: Endpoint
            let arrivalAirport: Endpoint
            let duration: Int?
            let airline: String?
            let flightNumber: String?
        }

        struct Endpoint: Decodable {
            let id: String?
            let time: String?
        }
    }
}

private extension FlightSegment {
    var duration: Int { max(0, Int(arrival.timeIntervalSince(departure) / 60)) }
}
