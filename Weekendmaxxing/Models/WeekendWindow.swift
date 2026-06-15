import Foundation

/// A depart/return date pair representing a single weekend getaway.
struct WeekendWindow: Hashable, Codable, Identifiable {
    var departureDate: Date
    var returnDate: Date

    var id: String {
        "\(Self.keyFormatter.string(from: departureDate))_\(Self.keyFormatter.string(from: returnDate))"
    }

    /// Number of nights away.
    var nights: Int {
        AppTime.calendar.dateComponents([.day], from: departureDate, to: returnDate).day ?? 0
    }

    private static let keyFormatter: DateFormatter = AppTime.dateFormatter("yyyy-MM-dd")
}

extension WeekendWindow {
    /// ISO `yyyy-MM-dd` departure string for API requests.
    var departureAPIString: String { Self.keyFormatter.string(from: departureDate) }
    /// ISO `yyyy-MM-dd` return string for API requests.
    var returnAPIString: String { Self.keyFormatter.string(from: returnDate) }
}
