import Foundation

/// Loads the bundled European city catalogue and provides fast lookup by IATA
/// code. Used by the Search picker, the mock service, and to resolve API codes
/// into human-readable names. Immutable after init, hence safe to share.
final class CityCatalog: @unchecked Sendable {
    static let shared = CityCatalog()

    let cities: [City]
    private let byCode: [String: City]

    private init() {
        let loaded = CityCatalog.loadFromBundle()
        let cities = loaded.isEmpty ? CityCatalog.fallback : loaded
        self.cities = cities.sorted { $0.name < $1.name }
        self.byCode = Dictionary(cities.map { ($0.code, $0) }, uniquingKeysWith: { first, _ in first })
    }

    func city(forCode code: String) -> City? {
        byCode[code.uppercased()]
    }

    /// Returns the catalogue city, or a best-effort placeholder for unknown codes.
    func cityOrPlaceholder(forCode code: String) -> City {
        byCode[code.uppercased()] ?? City(
            code: code.uppercased(),
            name: code.uppercased(),
            country: "",
            countryCode: "",
            basePrice: 0
        )
    }

    private static func loadFromBundle() -> [City] {
        guard let url = Bundle.main.url(forResource: "destinations", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        return (try? JSONDecoder().decode([City].self, from: data)) ?? []
    }

    /// Minimal safety net if the bundled JSON is ever missing.
    private static let fallback: [City] = [
        City(code: "PAR", name: "Paris", country: "France", countryCode: "FR", basePrice: 62),
        City(code: "AMS", name: "Amsterdam", country: "Netherlands", countryCode: "NL", basePrice: 71),
        City(code: "BCN", name: "Barcelona", country: "Spain", countryCode: "ES", basePrice: 56),
        City(code: "DUB", name: "Dublin", country: "Ireland", countryCode: "IE", basePrice: 44)
    ]
}
