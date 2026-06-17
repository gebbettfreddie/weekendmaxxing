import Foundation

/// Tuning for the "exactly what you asked for" match notifications. Kept free of
/// UI/IO so the rules are easy to reason about. De-dupe windows live on
/// `MatchStore`; this holds the scan horizon, the per-run cap, and the predicate
/// that decides whether a destination is a genuine preference match.
enum MatchRules {
    /// How far ahead to scan for matches.
    static let monthsAhead = 3
    /// Max match notifications fired per background run (avoid spamming).
    static let maxNotificationsPerRun = 3

    /// Whether a destination satisfies the traveller's vibe, region, and budget.
    static func isPreferenceMatch(_ destination: Destination, prefs: TravelPreferences) -> Bool {
        guard prefs.matches(city: destination.city) else { return false }
        if let maxPrice = prefs.maxPriceParam, destination.price.amount > Double(maxPrice) {
            return false
        }
        return true
    }
}
