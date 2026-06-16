import Foundation

/// Generates believable, deterministic trip data from the bundled city
/// catalogue so the app is fully usable without any API keys.
struct MockTripService: TripService {
    private let catalog = CityCatalog.shared

    // Simulate a little latency so loading states are visible.
    private let artificialDelayNanos: UInt64 = 350_000_000

    private static let carriers: [(code: String, name: String)] = [
        ("BA", "British Airways"), ("FR", "Ryanair"), ("U2", "easyJet"),
        ("VY", "Vueling"), ("AF", "Air France"), ("KL", "KLM"),
        ("LH", "Lufthansa"), ("IB", "Iberia"), ("TP", "TAP Air Portugal"),
        ("AZ", "ITA Airways"), ("SK", "SAS"), ("W6", "Wizz Air"),
        ("EW", "Eurowings"), ("LX", "SWISS"), ("OS", "Austrian"), ("AY", "Finnair")
    ]

    private static let connectionHubs = ["AMS", "CDG", "FRA", "MAD", "MUC", "BRU"]
    private static let departureHours = [6, 7, 9, 11, 13, 16, 18, 20, 21]

    // MARK: - Discovery

    func cheapestDestinations(
        origin: String,
        maxPrice: Int?,
        weekend: WeekendWindow
    ) async throws -> [Destination] {
        try? await Task.sleep(nanoseconds: artificialDelayNanos)

        let destinations = catalog.cities.map { city -> Destination in
            let amount = price(for: city, origin: origin, weekend: weekend)
            return Destination(
                city: city,
                price: Price(amount: amount, currency: "GBP"),
                weekend: weekend
            )
        }

        let filtered: [Destination]
        if let maxPrice {
            filtered = destinations.filter { $0.price.amount <= Double(maxPrice) }
        } else {
            filtered = destinations
        }

        return filtered.sorted { $0.price.amount < $1.price.amount }
    }

    // MARK: - Search

    func offers(
        origin: String,
        destination: String,
        weekend: WeekendWindow,
        adults: Int
    ) async throws -> [TripOffer] {
        try? await Task.sleep(nanoseconds: artificialDelayNanos)

        let city = catalog.cityOrPlaceholder(forCode: destination)
        let originAirport = representativeAirport(for: origin)
        var gen = SeededGenerator(seed: "offers-\(origin)-\(destination)-\(weekend.id)")

        let cheapest = price(for: city, origin: origin, weekend: weekend)
        let offerCount = Int.random(in: 4...6, using: &gen)
        let flightMinutes = approxFlightMinutes(for: destination)

        var offers: [TripOffer] = []
        for index in 0..<offerCount {
            let carrier = Self.carriers[Int.random(in: 0..<Self.carriers.count, using: &gen)]
            let hasStop = Int.random(in: 0..<10, using: &gen) >= 7 // ~30% with a connection

            let outbound = makeItinerary(
                date: weekend.departureDate,
                from: originAirport,
                to: destination,
                baseMinutes: flightMinutes,
                hasStop: hasStop,
                carrier: carrier,
                generator: &gen
            )
            let inbound = makeItinerary(
                date: weekend.returnDate,
                from: destination,
                to: originAirport,
                baseMinutes: flightMinutes,
                hasStop: hasStop,
                carrier: carrier,
                generator: &gen
            )

            let priceBump = index == 0 ? 0 : Int.random(in: 6...70, using: &gen)
            let stopDiscount = hasStop ? Int.random(in: 5...18, using: &gen) : 0
            let amount = max(19, cheapest + Double(priceBump) - Double(stopDiscount))

            offers.append(
                TripOffer(
                    id: "\(carrier.code)-\(destination)-\(weekend.id)-\(index)",
                    price: Price(amount: amount.rounded(), currency: "GBP"),
                    outbound: outbound,
                    inbound: inbound,
                    validatingAirline: carrier.code,
                    validatingAirlineName: carrier.name,
                    destinationCity: city,
                    seatsRemaining: Int.random(in: 1...9, using: &gen),
                    source: .sample
                )
            )
        }

        return offers.sorted { $0.price.amount < $1.price.amount }
    }

    // MARK: - Pricing

    private func price(for city: City, origin: String, weekend: WeekendWindow) -> Double {
        var gen = SeededGenerator(seed: "price-\(city.code)-\(origin)-\(weekend.id)")
        let originMult = originMultiplier(origin)
        let days = AppTime.calendar.dateComponents([.day], from: Date(), to: weekend.departureDate).day ?? 0
        let weeks = max(0, days) / 7
        let weekendMult = max(0.82, 1.12 - Double(weeks) * 0.03)
        let jitter = Double(Int.random(in: -8...14, using: &gen))
        let raw = city.basePrice * originMult * weekendMult + jitter
        return max(19, raw.rounded())
    }

    private func originMultiplier(_ origin: String) -> Double {
        switch origin.uppercased() {
        case "LHR": return 1.15
        case "LCY": return 1.22
        case "STN", "LTN": return 0.86
        case "LGW": return 0.98
        default: return 1.0 // LON / all airports
        }
    }

    private func representativeAirport(for origin: String) -> String {
        origin.uppercased() == "LON" ? "LGW" : origin.uppercased()
    }

    /// A stable, plausible one-way flight time per destination.
    private func approxFlightMinutes(for code: String) -> Int {
        70 + Int(SeededGenerator.stableHash("dur-\(code)") % 165)
    }

    // MARK: - Itinerary building

    private func makeItinerary(
        date: Date,
        from: String,
        to: String,
        baseMinutes: Int,
        hasStop: Bool,
        carrier: (code: String, name: String),
        generator gen: inout SeededGenerator
    ) -> Itinerary {
        let departHour = Self.departureHours[Int.random(in: 0..<Self.departureHours.count, using: &gen)]
        let departMinute = [0, 15, 30, 45][Int.random(in: 0..<4, using: &gen)]
        let departure = setTime(date, hour: departHour, minute: departMinute)

        if hasStop {
            let hub = Self.connectionHubs.first { $0 != from && $0 != to } ?? "AMS"
            let firstLeg = max(45, baseMinutes / 2 + Int.random(in: -10...10, using: &gen))
            let layover = Int.random(in: 55...130, using: &gen)
            let secondLeg = max(45, baseMinutes / 2 + Int.random(in: -10...20, using: &gen))

            let arr1 = addMinutes(firstLeg, to: departure)
            let dep2 = addMinutes(layover, to: arr1)
            let arr2 = addMinutes(secondLeg, to: dep2)

            let seg1 = FlightSegment(
                origin: from, destination: hub,
                departure: departure, arrival: arr1,
                carrierCode: carrier.code, carrierName: carrier.name,
                flightNumber: "\(Int.random(in: 100...1999, using: &gen))"
            )
            let seg2 = FlightSegment(
                origin: hub, destination: to,
                departure: dep2, arrival: arr2,
                carrierCode: carrier.code, carrierName: carrier.name,
                flightNumber: "\(Int.random(in: 100...1999, using: &gen))"
            )
            return Itinerary(segments: [seg1, seg2], durationMinutes: firstLeg + layover + secondLeg)
        } else {
            let arrival = addMinutes(baseMinutes, to: departure)
            let seg = FlightSegment(
                origin: from, destination: to,
                departure: departure, arrival: arrival,
                carrierCode: carrier.code, carrierName: carrier.name,
                flightNumber: "\(Int.random(in: 100...1999, using: &gen))"
            )
            return Itinerary(segments: [seg], durationMinutes: baseMinutes)
        }
    }

    private func setTime(_ date: Date, hour: Int, minute: Int) -> Date {
        AppTime.calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }

    private func addMinutes(_ minutes: Int, to date: Date) -> Date {
        date.addingTimeInterval(TimeInterval(minutes * 60))
    }
}
