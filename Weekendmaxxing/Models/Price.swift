import Foundation

/// A monetary amount in a given ISO 4217 currency.
struct Price: Hashable, Codable {
    var amount: Double
    var currency: String

    init(amount: Double, currency: String = "GBP") {
        self.amount = amount
        self.currency = currency
    }
}

extension Price {
    /// e.g. "£128.40"
    var formatted: String {
        CurrencyFormatter.string(amount: amount, currency: currency)
    }

    /// e.g. "£128" – handy for compact price pills.
    var formattedRounded: String {
        CurrencyFormatter.string(amount: amount, currency: currency, fractionDigits: 0)
    }
}
