import Foundation

/// Loads the bundled European city catalogue and provides fast lookup by IATA
/// code. Used by the Search picker, the mock service, and to resolve API codes
/// into human-readable names. Immutable after init, hence safe to share.
final class CityCatalog: @unchecked Sendable {
    static let shared = CityCatalog()

    let cities: [City]
    private let byCode: [String: City]
    /// Full IATA code → city name/country lookup (≈10k entries) so live API
    /// results for cities outside the curated catalogue still show a real name
    /// instead of a bare 3-letter code.
    private let iataNames: [String: IataName]

    private struct IataName: Decodable {
        let n: String   // city name
        let c: String   // country name
        let cc: String  // ISO country code
    }

    private init() {
        let loaded = CityCatalog.loadFromBundle()
        let cities = loaded.isEmpty ? CityCatalog.fallback : loaded
        self.cities = cities.sorted { $0.name < $1.name }
        self.byCode = Dictionary(cities.map { ($0.code, $0) }, uniquingKeysWith: { first, _ in first })
        self.iataNames = CityCatalog.loadIataNames()
    }

    func city(forCode code: String) -> City? {
        byCode[code.uppercased()]
    }

    /// Resolves an IATA code to a city. Prefers the curated catalogue (which has
    /// a hand-picked photo), then the bundled IATA name table (full name +
    /// country, photo derived from the name), and finally a bare-code placeholder.
    func cityOrPlaceholder(forCode code: String) -> City {
        let upper = code.uppercased()
        if let city = byCode[upper] { return city }
        if let entry = iataNames[upper] {
            return City(
                code: upper,
                name: entry.n,
                country: entry.c,
                countryCode: entry.cc,
                basePrice: 0
            )
        }
        return City(code: upper, name: upper, country: "", countryCode: "", basePrice: 0)
    }

    private static func loadFromBundle() -> [City] {
        guard let url = Bundle.main.url(forResource: "destinations", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        return (try? JSONDecoder().decode([City].self, from: data)) ?? []
    }

    private static func loadIataNames() -> [String: IataName] {
        guard let url = Bundle.main.url(forResource: "iata", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return [:]
        }
        return (try? JSONDecoder().decode([String: IataName].self, from: data)) ?? [:]
    }

    /// Minimal safety net if the bundled JSON is ever missing.
    private static let fallback: [City] = [
        City(code: "PAR", name: "Paris", country: "France", countryCode: "FR", basePrice: 62),
        City(code: "AMS", name: "Amsterdam", country: "Netherlands", countryCode: "NL", basePrice: 71),
        City(code: "BCN", name: "Barcelona", country: "Spain", countryCode: "ES", basePrice: 56),
        City(code: "DUB", name: "Dublin", country: "Ireland", countryCode: "IE", basePrice: 44)
    ]
}
