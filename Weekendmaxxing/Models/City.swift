import Foundation

/// The kind of place a destination is, used to match against a traveller's
/// `TripVibe` preference. A city can be both (e.g. Barcelona).
enum CityVibe: String, Codable, CaseIterable, Identifiable, Hashable {
    case city
    case beach

    var id: String { rawValue }

    var title: String {
        switch self {
        case .city: return "City"
        case .beach: return "Beach"
        }
    }
}

/// A broad European region, used to match against a traveller's preferred
/// regions. Derived from a city's ISO country code when not set explicitly.
enum Region: String, Codable, CaseIterable, Identifiable, Hashable {
    case britishIsles
    case westernEurope
    case mediterranean
    case central
    case nordics
    case eastern
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .britishIsles: return "British Isles"
        case .westernEurope: return "Western Europe"
        case .mediterranean: return "Mediterranean"
        case .central: return "Central Europe"
        case .nordics: return "Nordics"
        case .eastern: return "Eastern Europe"
        case .other: return "Elsewhere"
        }
    }

    var systemImage: String {
        switch self {
        case .britishIsles: return "cloud.rain.fill"
        case .westernEurope: return "building.columns.fill"
        case .mediterranean: return "sun.max.fill"
        case .central: return "mountain.2.fill"
        case .nordics: return "snowflake"
        case .eastern: return "building.2.fill"
        case .other: return "globe.europe.africa.fill"
        }
    }

    /// Best-effort region for an ISO 3166-1 alpha-2 country code.
    init(countryCode: String) {
        switch countryCode.uppercased() {
        case "GB", "IE": self = .britishIsles
        case "FR", "NL", "BE", "LU": self = .westernEurope
        case "ES", "PT", "IT", "GR", "HR", "MT", "TR", "MA", "CY": self = .mediterranean
        case "DE", "AT", "CH", "CZ", "HU", "PL", "SK", "SI": self = .central
        case "DK", "SE", "NO", "FI", "IS": self = .nordics
        case "EE", "LV", "LT", "BG", "RO", "RS", "UA", "BA", "ME", "AL", "MK", "MD", "BY": self = .eastern
        default: self = .other
        }
    }
}

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
    /// Optional explicit vibe tags; when absent they're derived from the code.
    var vibes: Set<CityVibe>?
    /// Optional explicit region; when absent it's derived from the country code.
    var region: Region?

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

extension City {
    /// The region this city belongs to, using the explicit value if set and
    /// otherwise deriving it from the country code (so live API cities are
    /// classified too).
    var resolvedRegion: Region {
        region ?? Region(countryCode: countryCode)
    }

    /// The vibe tags for this city, using explicit values if set and otherwise
    /// deriving them from a curated list of beach destinations.
    var resolvedVibes: Set<CityVibe> {
        if let vibes, !vibes.isEmpty { return vibes }
        return Self.derivedVibes(forCode: code)
    }

    /// Whether this city satisfies a traveller's `TripVibe` preference.
    func matches(vibe: TripVibe) -> Bool {
        switch vibe {
        case .either: return true
        case .city: return resolvedVibes.contains(.city)
        case .beach: return resolvedVibes.contains(.beach)
        }
    }

    /// Island / resort destinations that are purely about the beach.
    private static let pureBeachCodes: Set<String> = [
        "FAO", "PMI", "MAH", "IBZ", "LPA", "ACE", "TFS", "JTR", "FNC"
    ]
    /// Coastal cities that offer both a city break and beach time.
    private static let beachAndCityCodes: Set<String> = [
        "BCN", "NCE", "LIS", "AGP", "VLC", "ALC", "MLA", "DBV", "SPU",
        "NAP", "BRI", "MRS", "SKG", "ATH", "CTA", "OPO"
    ]

    static func derivedVibes(forCode code: String) -> Set<CityVibe> {
        let upper = code.uppercased()
        if pureBeachCodes.contains(upper) { return [.beach] }
        if beachAndCityCodes.contains(upper) { return [.city, .beach] }
        return [.city]
    }
}
