import Foundation

/// A discovered weekend destination: a city plus its cheapest price and the
/// weekend window the price applies to.
struct Destination: Identifiable, Hashable, Codable {
    var city: City
    var price: Price
    var weekend: WeekendWindow

    var id: String { city.code }
}

extension Destination {
    var name: String { city.name }
    var country: String { city.country }
    var flagEmoji: String { city.flagEmoji }
}
