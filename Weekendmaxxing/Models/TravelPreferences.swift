import Foundation

/// The kind of getaway a traveller is in the mood for. Captured during
/// onboarding; not yet used for filtering (no destination metadata exists).
enum TripVibe: String, Codable, CaseIterable, Identifiable {
    case city
    case beach
    case either

    var id: String { rawValue }

    var title: String {
        switch self {
        case .city: return "City break"
        case .beach: return "Beach break"
        case .either: return "Either"
        }
    }

    var systemImage: String {
        switch self {
        case .city: return "building.2.fill"
        case .beach: return "beach.umbrella.fill"
        case .either: return "sparkles"
        }
    }
}

/// Where the traveller is happy to stay. Multi-select; captured during
/// onboarding for future use.
enum AccommodationType: String, Codable, CaseIterable, Identifiable {
    case hostel
    case hotel
    case apartment
    case bnb
    /// "No preference" — any kind of stay works. Mutually exclusive with the
    /// specific types above.
    case anywhere

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hostel: return "Hostel"
        case .hotel: return "Hotel"
        case .apartment: return "Apartment"
        case .bnb: return "B&B"
        case .anywhere: return "Anywhere"
        }
    }

    var systemImage: String {
        switch self {
        case .hostel: return "bed.double.fill"
        case .hotel: return "building.fill"
        case .apartment: return "house.fill"
        case .bnb: return "cup.and.saucer.fill"
        case .anywhere: return "globe"
        }
    }
}

/// How far from the arrival airport the traveller is willing to be. Captured
/// during onboarding for future use.
enum AirportDistance: String, Codable, CaseIterable, Identifiable {
    case nearAirport
    case upTo30
    case upTo60
    case any

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nearAirport: return "Right by the airport"
        case .upTo30: return "Up to 30 min away"
        case .upTo60: return "Up to 1 hour away"
        case .any: return "Distance doesn't matter"
        }
    }

    var systemImage: String {
        switch self {
        case .nearAirport: return "airplane.circle.fill"
        case .upTo30: return "tram.fill"
        case .upTo60: return "car.fill"
        case .any: return "map.fill"
        }
    }
}

/// A traveller's saved trip preferences, captured during first-run onboarding
/// and persisted via `PreferencesStore`.
struct TravelPreferences: Codable, Equatable {
    /// 50...500; 500 is treated as "Any budget" (matches the Discover slider).
    var maxBudget: Double = 200
    var weekendStyle: WeekendStyle = .fridayToSunday
    var tripVibe: TripVibe = .either
    var accommodationTypes: Set<AccommodationType> = [.hotel]
    var airportDistance: AirportDistance = .any
    /// Regions the traveller wants to see; empty means anywhere in Europe.
    var preferredRegions: Set<Region> = []
    var notificationsEnabled: Bool = false
}

extension TravelPreferences {
    /// The budget passed to the API/services; `nil` means "any budget".
    var maxPriceParam: Int? { maxBudget >= 500 ? nil : Int(maxBudget) }

    /// Whether a destination satisfies the traveller's vibe + region filters.
    func matches(city: City) -> Bool {
        guard city.matches(vibe: tripVibe) else { return false }
        guard preferredRegions.isEmpty || preferredRegions.contains(city.resolvedRegion) else {
            return false
        }
        return true
    }
}
