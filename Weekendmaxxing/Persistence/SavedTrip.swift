import Foundation
import SwiftData

/// A trip the user has saved for later. Stores enough to render the card and,
/// for offers, the full encoded `TripOffer` so the detail screen can rebuild it.
@Model
final class SavedTrip {
    var id: String
    var kind: String
    var cityCode: String
    var cityName: String
    var country: String
    var countryCode: String
    var priceAmount: Double
    var priceCurrency: String
    var departureDate: Date
    var returnDate: Date
    var airline: String?
    var isDirect: Bool
    var savedAt: Date
    var offerData: Data?

    init(
        id: String,
        kind: String,
        cityCode: String,
        cityName: String,
        country: String,
        countryCode: String,
        priceAmount: Double,
        priceCurrency: String,
        departureDate: Date,
        returnDate: Date,
        airline: String? = nil,
        isDirect: Bool = false,
        savedAt: Date = Date(),
        offerData: Data? = nil
    ) {
        self.id = id
        self.kind = kind
        self.cityCode = cityCode
        self.cityName = cityName
        self.country = country
        self.countryCode = countryCode
        self.priceAmount = priceAmount
        self.priceCurrency = priceCurrency
        self.departureDate = departureDate
        self.returnDate = returnDate
        self.airline = airline
        self.isDirect = isDirect
        self.savedAt = savedAt
        self.offerData = offerData
    }
}

extension SavedTrip {
    convenience init(destination: Destination) {
        self.init(
            id: "dest-\(destination.city.code)-\(destination.weekend.id)",
            kind: "destination",
            cityCode: destination.city.code,
            cityName: destination.city.name,
            country: destination.city.country,
            countryCode: destination.city.countryCode,
            priceAmount: destination.price.amount,
            priceCurrency: destination.price.currency,
            departureDate: destination.weekend.departureDate,
            returnDate: destination.weekend.returnDate
        )
    }

    convenience init(offer: TripOffer, weekend: WeekendWindow) {
        let city = offer.destinationCity
            ?? CityCatalog.shared.cityOrPlaceholder(forCode: offer.outbound.destination ?? "")
        self.init(
            id: "offer-\(offer.id)",
            kind: "offer",
            cityCode: city.code,
            cityName: city.name,
            country: city.country,
            countryCode: city.countryCode,
            priceAmount: offer.price.amount,
            priceCurrency: offer.price.currency,
            departureDate: weekend.departureDate,
            returnDate: weekend.returnDate,
            airline: offer.airlineDisplay,
            isDirect: offer.isDirect,
            offerData: try? JSONEncoder().encode(offer)
        )
    }

    var price: Price { Price(amount: priceAmount, currency: priceCurrency) }

    var weekend: WeekendWindow {
        WeekendWindow(departureDate: departureDate, returnDate: returnDate)
    }

    var flagEmoji: String {
        City(code: cityCode, name: cityName, country: country, countryCode: countryCode, basePrice: 0).flagEmoji
    }

    /// Decoded offer, if this saved trip represents a specific offer.
    var decodedOffer: TripOffer? {
        guard let offerData else { return nil }
        return try? JSONDecoder().decode(TripOffer.self, from: offerData)
    }

    var isOffer: Bool { kind == "offer" }
}
