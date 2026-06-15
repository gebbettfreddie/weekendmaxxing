import Foundation

/// Decodes the `aviasales/v3/prices_for_dates` response.
///
/// The same endpoint powers both discovery (omit `destination` to get the
/// cheapest fare to every reachable city) and route search (pass a
/// `destination` to get concrete fares for one route).
struct TravelpayoutsPricesResponse: Decodable {
    let success: Bool?
    let currency: String?
    let data: [Fare]
    let error: String?

    struct Fare: Decodable {
        let origin: String?
        let destination: String?
        let originAirport: String?
        let destinationAirport: String?
        let price: Double?
        let airline: String?
        let flightNumber: FlexibleString?
        let departureAt: String?
        let returnAt: String?
        let transfers: Int?
        let returnTransfers: Int?
        let duration: Int?
        let durationTo: Int?
        let durationBack: Int?
        let link: String?

        enum CodingKeys: String, CodingKey {
            case origin, destination, price, airline, transfers, duration, link
            case originAirport = "origin_airport"
            case destinationAirport = "destination_airport"
            case flightNumber = "flight_number"
            case departureAt = "departure_at"
            case returnAt = "return_at"
            case returnTransfers = "return_transfers"
            case durationTo = "duration_to"
            case durationBack = "duration_back"
        }
    }
}

/// `flight_number` arrives as a JSON number, but treating it as text keeps the
/// model resilient if the API ever switches to alphanumeric values.
struct FlexibleString: Decodable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = String(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            value = String(Int(doubleValue))
        } else {
            value = (try? container.decode(String.self)) ?? ""
        }
    }
}
