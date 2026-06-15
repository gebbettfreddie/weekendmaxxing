import Foundation

/// Currency formatting helpers (defaults to a GBP-friendly British locale).
enum CurrencyFormatter {
    private static var cache: [String: NumberFormatter] = [:]

    static func string(amount: Double, currency: String, fractionDigits: Int = 2) -> String {
        let key = "\(currency)-\(fractionDigits)"
        let formatter: NumberFormatter
        if let cached = cache[key] {
            formatter = cached
        } else {
            let f = NumberFormatter()
            f.numberStyle = .currency
            f.currencyCode = currency
            f.locale = Locale(identifier: "en_GB")
            f.maximumFractionDigits = fractionDigits
            f.minimumFractionDigits = fractionDigits
            cache[key] = f
            formatter = f
        }
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(Int(amount))"
    }
}

/// Date / duration presentation helpers.
enum DateUtil {
    private static let dayMonthFormatter = AppTime.dateFormatter("EEE d MMM")
    private static let dayShortFormatter = AppTime.dateFormatter("EEE d")
    private static let timeFormatter = AppTime.dateFormatter("HH:mm")

    /// e.g. "Fri 19 Jun"
    static func dayMonth(_ date: Date) -> String { dayMonthFormatter.string(from: date) }

    /// e.g. "07:45"
    static func time(_ date: Date) -> String { timeFormatter.string(from: date) }

    /// e.g. "Fri 19 – Sun 21 Jun"
    static func weekendLabel(_ window: WeekendWindow) -> String {
        let cal = AppTime.calendar
        let sameMonth = cal.component(.month, from: window.departureDate)
            == cal.component(.month, from: window.returnDate)
        if sameMonth {
            return "\(dayShortFormatter.string(from: window.departureDate)) – \(dayMonthFormatter.string(from: window.returnDate))"
        } else {
            return "\(dayMonthFormatter.string(from: window.departureDate)) – \(dayMonthFormatter.string(from: window.returnDate))"
        }
    }

    /// Friendly relative label for the soonest weekends, falling back to dates.
    static func relativeWeekendLabel(_ window: WeekendWindow, index: Int) -> String {
        switch index {
        case 0: return "This weekend"
        case 1: return "Next weekend"
        default: return weekendLabel(window)
        }
    }

    /// e.g. "2h 15m"
    static func duration(minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
