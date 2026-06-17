import Foundation

/// A discovered weekend destination: a city plus its cheapest price and the
/// weekend window the price applies to.
struct Destination: Identifiable, Hashable, Codable {
    var city: City
    var price: Price
    var weekend: WeekendWindow
    /// The route's typical/average fare, when the data source provides it (e.g.
    /// Google's `average_price`). Used as a baseline for deal detection.
    var typicalPrice: Double? = nil

    var id: String { city.code }
}

extension Destination {
    var name: String { city.name }
    var country: String { city.country }
    var flagEmoji: String { city.flagEmoji }
}
