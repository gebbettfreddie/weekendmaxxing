import Foundation

/// Live trip data backed by the Travelpayouts (Aviasales) Flight Data API.
///
/// Travelpayouts replaced the Amadeus Self-Service APIs after Amadeus
/// decommissioned its self-service portal. A single endpoint —
/// `aviasales/v3/prices_for_dates` — covers both of the app's needs:
///   * Discovery: cheapest fares from an origin to *any* destination for a
///     given weekend (omit the `destination` parameter).
///   * Search: concrete fares for a specific origin → destination route.
///
/// Prices are *indicative* (cached from real searches) rather than live
/// bookable quotes, which suits an inspiration app that hands off to Aviasales
/// to complete the booking.
struct TravelpayoutsTripService: TripService {
    private let token: String
    private let marker: String?
    private let currency: String
    private let market: String
    private let baseURL = URL(string: "https://api.travelpayouts.com")!
    private let session: URLSession
    private let catalog = CityCatalog.shared

    init(
        token: String,
        marker: String?,
        currency: String = "gbp",
        market: String = "uk",
        session: URLSession = .shared
    ) {
        self.token = token
        self.marker = marker
        self.currency = currency
        self.market = market
        self.session = session
    }

    // MARK: - Discovery

    func cheapestDestinations(
        origin: String,
        maxPrice: Int?,
        weekend: WeekendWindow
    ) async throws -> [Destination] {
        var items: [URLQueryItem] = [
            .init(name: "origin", value: origin.uppercased()),
            .init(name: "departure_at", value: weekend.departureAPIString),
            .init(name: "return_at", value: weekend.returnAPIString),
            .init(name: "unique", value: "true"),
            .init(name: "sorting", value: "price"),
            .init(name: "direct", value: "false"),
            .init(name: "currency", value: currency),
            .init(name: "market", value: market),
            .init(name: "limit", value: "100"),
            .init(name: "page", value: "1")
        ]
        if let marker { items.append(.init(name: "marker", value: marker)) }

        let response: TravelpayoutsPricesResponse = try await get(
            path: "aviasales/v3/prices_for_dates",
            queryItems: items
        )

        let resolvedCurrency = (response.currency ?? currency).uppercased()
        let destinations: [Destination] = response.data.compactMap { fare in
            guard let code = fare.destination, let amount = fare.price else { return nil }
            if let maxPrice, amount > Double(maxPrice) { return nil }
            let city = catalog.cityOrPlaceholder(forCode: code)
            let window = parseWindow(
                departure: fare.departureAt,
                returnDate: fare.returnAt
            ) ?? weekend
            return Destination(
                city: city,
                price: Price(amount: amount, currency: resolvedCurrency),
                weekend: window
            )
        }

        // The API can return several fares per city; keep the cheapest of each.
        var cheapestByCity: [String: Destination] = [:]
        for destination in destinations {
            if let existing = cheapestByCity[destination.id],
               existing.price.amount <= destination.price.amount { continue }
            cheapestByCity[destination.id] = destination
        }

        return cheapestByCity.values.sorted { $0.price.amount < $1.price.amount }
    }

    // MARK: - Search

    func offers(
        origin: String,
        destination: String,
        weekend: WeekendWindow,
        adults: Int
    ) async throws -> [TripOffer] {
        var items: [URLQueryItem] = [
            .init(name: "origin", value: origin.uppercased()),
            .init(name: "destination", value: destination.uppercased()),
            .init(name: "departure_at", value: weekend.departureAPIString),
            .init(name: "return_at", value: weekend.returnAPIString),
            .init(name: "sorting", value: "price"),
            .init(name: "direct", value: "false"),
            .init(name: "currency", value: currency),
            .init(name: "market", value: market),
            .init(name: "limit", value: "30"),
            .init(name: "page", value: "1")
        ]
        if let marker { items.append(.init(name: "marker", value: marker)) }

        let response: TravelpayoutsPricesResponse = try await get(
            path: "aviasales/v3/prices_for_dates",
            queryItems: items
        )

        let resolvedCurrency = (response.currency ?? currency).uppercased()
        let city = catalog.cityOrPlaceholder(forCode: destination)

        let offers: [TripOffer] = response.data.enumerated().compactMap { index, fare in
            guard let amount = fare.price, let departure = fare.departureAt else { return nil }

            let airline = fare.airline ?? ""
            let from = (fare.originAirport ?? fare.origin ?? origin).uppercased()
            let to = (fare.destinationAirport ?? fare.destination ?? destination).uppercased()

            let outbound = makeItinerary(
                from: from,
                to: to,
                departureString: departure,
                durationMinutes: fare.durationTo,
                transfers: fare.transfers,
                airline: airline,
                flightNumber: fare.flightNumber?.value ?? ""
            )

            let inbound: Itinerary? = fare.returnAt.map { returnString in
                makeItinerary(
                    from: to,
                    to: from,
                    departureString: returnString,
                    durationMinutes: fare.durationBack,
                    transfers: fare.returnTransfers,
                    airline: airline,
                    flightNumber: ""
                )
            }

            let id = "\(airline)\(fare.flightNumber?.value ?? "")-\(to)-\(departure)-\(index)"

            return TripOffer(
                id: id,
                price: Price(amount: amount, currency: resolvedCurrency),
                outbound: outbound,
                inbound: inbound,
                validatingAirline: airline,
                validatingAirlineName: Self.airlineName(for: airline),
                destinationCity: city,
                seatsRemaining: nil,
                deepLinkURL: bookingURL(for: fare.link),
                source: .cached
            )
        }

        return offers.sorted { $0.price.amount < $1.price.amount }
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
        request.setValue(token, forHTTPHeaderField: "X-Access-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        await MainActor.run { APIUsageTracker.shared.record(.travelpayouts) }

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
            // 429 means the free monthly quota is exhausted; surface it clearly.
            if http.statusCode == 429 {
                throw TripServiceError.server(status: 429, message: "Rate limit reached. Try again shortly.")
            }
            let message = (try? JSONDecoder().decode(TravelpayoutsPricesResponse.self, from: data))?.error
            throw TripServiceError.server(status: http.statusCode, message: message)
        }

        let decoded: T
        do {
            decoded = try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw TripServiceError.decoding(error.localizedDescription)
        }

        // A 200 with `success: false` signals a bad request (e.g. unknown IATA).
        if let prices = decoded as? TravelpayoutsPricesResponse, prices.success == false {
            throw TripServiceError.noResults
        }
        return decoded
    }

    // MARK: - Mapping helpers

    /// Builds a single-segment itinerary from the summary fields Travelpayouts
    /// returns. Connecting airports aren't provided, so when there are stops we
    /// keep one segment and record the transfer count via `stopCountOverride`.
    private func makeItinerary(
        from: String,
        to: String,
        departureString: String,
        durationMinutes: Int?,
        transfers: Int?,
        airline: String,
        flightNumber: String
    ) -> Itinerary {
        let departure = parseDateTime(departureString)
        let minutes = max(0, durationMinutes ?? 0)
        let arrival = departure.addingTimeInterval(TimeInterval(minutes * 60))

        let segment = FlightSegment(
            origin: from,
            destination: to,
            departure: departure,
            arrival: arrival,
            carrierCode: airline,
            carrierName: Self.airlineName(for: airline),
            flightNumber: flightNumber
        )

        return Itinerary(
            segments: [segment],
            durationMinutes: minutes,
            stopCountOverride: max(0, transfers ?? 0)
        )
    }

    private func bookingURL(for link: String?) -> URL? {
        guard let link, !link.isEmpty else { return nil }
        if link.hasPrefix("http") { return URL(string: link) }

        var components = URLComponents(string: "https://www.aviasales.com")
        components?.path = link.hasPrefix("/") ? link : "/\(link)"
        if let marker {
            var queryItems = components?.queryItems ?? []
            queryItems.append(.init(name: "marker", value: marker))
            components?.queryItems = queryItems
        }
        return components?.url
    }

    private func parseWindow(departure: String?, returnDate: String?) -> WeekendWindow? {
        guard let departure, let dep = Self.dateOnly.date(from: String(departure.prefix(10))) else {
            return nil
        }
        let ret = returnDate.flatMap { Self.dateOnly.date(from: String($0.prefix(10))) }
            ?? AppTime.calendar.date(byAdding: .day, value: 2, to: dep) ?? dep
        return WeekendWindow(departureDate: dep, returnDate: ret)
    }

    /// Travelpayouts timestamps carry a local UTC offset (e.g. `+01:00`). The
    /// app intentionally treats every clock time as UTC so displayed times match
    /// the airport's local wall clock, so we keep the wall-clock portion and
    /// drop the offset.
    private func parseDateTime(_ string: String) -> Date {
        let wallClock = String(string.prefix(19)) // "yyyy-MM-dd'T'HH:mm:ss"
        return Self.dateTime.date(from: wallClock)
            ?? Self.dateOnly.date(from: String(string.prefix(10)))
            ?? Date()
    }

    // MARK: - Formatters

    private static let dateOnly = AppTime.dateFormatter("yyyy-MM-dd")
    private static let dateTime = AppTime.dateFormatter("yyyy-MM-dd'T'HH:mm:ss")

    /// Best-effort IATA airline code → display name. Travelpayouts returns only
    /// the code; unknown codes fall back to the code itself in the UI.
    private static let airlineNames: [String: String] = [
        "BA": "British Airways", "FR": "Ryanair", "U2": "easyJet", "VY": "Vueling",
        "AF": "Air France", "KL": "KLM", "LH": "Lufthansa", "IB": "Iberia",
        "TP": "TAP Air Portugal", "AZ": "ITA Airways", "SK": "SAS", "W6": "Wizz Air",
        "EW": "Eurowings", "LX": "SWISS", "OS": "Austrian", "AY": "Finnair",
        "EI": "Aer Lingus", "DY": "Norwegian", "TK": "Turkish Airlines", "A3": "Aegean",
        "SN": "Brussels Airlines", "LO": "LOT Polish", "OK": "Czech Airlines",
        "FI": "Icelandair", "WizzUK": "Wizz Air UK", "EJU": "easyJet Europe",
        "HV": "Transavia", "PC": "Pegasus", "VS": "Virgin Atlantic", "LS": "Jet2",
        "BT": "airBaltic", "RO": "TAROM", "JU": "Air Serbia"
    ]

    static func airlineName(for code: String) -> String? {
        airlineNames[code]
    }
}
