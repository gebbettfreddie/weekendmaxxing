import Foundation

/// A single, fixed time basis used for all date construction, parsing, and
/// display in the app. We treat every clock time as UTC so the numbers the
/// API (or mock) produce are preserved verbatim end-to-end and day labels
/// never drift across time zones.
enum AppTime {
    static let timeZone = TimeZone(identifier: "UTC")!
    static let locale = Locale(identifier: "en_GB")

    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        cal.locale = locale
        return cal
    }

    static func dateFormatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.timeZone = timeZone
        f.dateFormat = format
        return f
    }
}
