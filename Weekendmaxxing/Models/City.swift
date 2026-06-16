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

    /// A destination photo for banners/cards. Uses an explicit `imageURL` when
    /// provided, otherwise derives a stable cityscape photo from the city name.
    /// Returns `nil` for placeholder cities where only the IATA code is known,
    /// so the banner falls back to its gradient + flag.
    var photoURL: URL? {
        if let imageURL { return imageURL }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.uppercased() != code.uppercased() else { return nil }
        let keyword = trimmed
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US"))
            .lowercased()
        let slug = keyword.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? keyword
        // `lock` keeps the same image for a given city across launches.
        let lock = SeededGenerator.stableHash(code) % 1000
        return URL(string: "https://loremflickr.com/800/600/\(slug),city?lock=\(lock)")
    }
}
