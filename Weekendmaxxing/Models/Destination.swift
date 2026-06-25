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
    /// Cheapest stay *total* for this weekend (nights × nightly), when known.
    /// Set during discovery so the deck can headline a complete package price.
    /// Optional + defaulted so older persisted decks decode unchanged.
    var stayFrom: Price? = nil

    var id: String { city.code }
}

extension Destination {
    var name: String { city.name }
    var country: String { city.country }
    var flagEmoji: String { city.flagEmoji }

    /// Flights + cheapest stay, when a stay price is known; otherwise nil so
    /// callers can fall back to showing the flight fare alone.
    var packageFrom: Price? {
        guard let stayFrom else { return nil }
        return Price(amount: price.amount + stayFrom.amount, currency: price.currency)
    }
}
