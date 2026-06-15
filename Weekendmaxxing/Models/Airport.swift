import Foundation

/// A bookable origin airport (or grouped city) the traveller departs from.
struct Airport: Hashable, Codable, Identifiable {
    /// IATA code, e.g. "LHR", or a city code such as "LON" for all London airports.
    var code: String
    var name: String
    var cityName: String

    var id: String { code }
}

extension Airport {
    /// London origins offered in the Discover/Search controls.
    static let londonAll = Airport(code: "LON", name: "All London airports", cityName: "London")
    static let heathrow = Airport(code: "LHR", name: "Heathrow", cityName: "London")
    static let gatwick = Airport(code: "LGW", name: "Gatwick", cityName: "London")
    static let stansted = Airport(code: "STN", name: "Stansted", cityName: "London")
    static let luton = Airport(code: "LTN", name: "Luton", cityName: "London")
    static let cityAirport = Airport(code: "LCY", name: "City", cityName: "London")

    static let londonOrigins: [Airport] = [
        .londonAll, .heathrow, .gatwick, .stansted, .luton, .cityAirport
    ]
}
