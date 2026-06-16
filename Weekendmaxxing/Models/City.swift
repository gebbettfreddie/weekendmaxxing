import Foundation

/// A reference European destination city. Doubles as the catalogue used to
/// resolve IATA codes returned by the API into human-readable names, and as
/// the seed data for the mock service.
struct City: Identifiable, Hashable, Codable {
    /// IATA city/airport code, e.g. "BCN".
    var code: String
    var name: String
    var country: String
    /// ISO 3166-1 alpha-2 code, e.g. "ES" – used to render a flag emoji.
    var countryCode: String
    /// Typical round-trip fare from London in GBP (used by the mock service).
    var basePrice: Double
    var imageURL: URL?

    var id: String { code }
}

extension City {
    /// Regional-indicator flag emoji derived from the ISO country code.
    var flagEmoji: String {
        let base: UInt32 = 0x1F1E6
        var result = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            guard let v = scalar.value as UInt32?, scalar.isASCII,
                  let flagScalar = Unicode.Scalar(base + (v - 65)) else { continue }
            result.unicodeScalars.append(flagScalar)
        }
        return result.isEmpty ? "🏳️" : result
    }

    var displayName: String { name }
    var subtitle: String { country }
}
