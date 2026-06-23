import Foundation

/// Persists the swipe deck, swipe history (passed cooldown), matched
/// destinations, and the match-notification de-dupe cache in `UserDefaults` so
/// the foreground deck and the background match-scan task share state. Mirrors
/// the `DealStore` convention.
final class MatchStore: @unchecked Sendable {
    static let shared = MatchStore()

    /// How many destinations to surface in the daily browse deck. The user can
    /// swipe through all of them, but may only *like* `dailyLikeLimit` per day.
    static let deckSize = 12
    /// Likes (match / super-match) allowed per day. Passes are unlimited. This
    /// caps how fast the matched set grows, which bounds the background
    /// price-monitor's API load.
    static let dailyLikeLimit = 3
    /// How long a passed destination stays hidden from the deck.
    static let passedCooldown: TimeInterval = 30 * 24 * 60 * 60
    /// Don't re-notify about the same match within this window…
    static let dedupeWindow: TimeInterval = 7 * 24 * 60 * 60
    /// …unless the price dropped at least this much since the last alert.
    static let realertPriceDrop = 0.10

    private let defaults: UserDefaults

    private enum Key {
        static let deck = "match.deck"           // DeckState
        static let passed = "match.passed"       // [cityCode: Date]
        static let matched = "match.matched"     // [cityCode: Destination]
        static let notified = "match.notified"   // [matchKey: NotifiedRecord]
        static let likes = "match.likes"         // LikeState
    }

    /// Today's like tally, reset implicitly when `dayKey` rolls over.
    private struct LikeState: Codable {
        var dayKey: String
        var count: Int
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Stable day bucket (UTC, matching the rest of the app's time basis).
    static func dayKey(for date: Date = Date()) -> String {
        dayFormatter.string(from: date)
    }

    private static let dayFormatter = AppTime.dateFormatter("yyyy-MM-dd")

    // MARK: - Deck

    /// The saved deck for `dayKey`, or nil if there isn't one for today.
    func deck(for dayKey: String) -> [DeckCard]? {
        guard let state = decode(DeckState.self, Key.deck), state.dayKey == dayKey else { return nil }
        return state.cards
    }

    func saveDeck(_ cards: [DeckCard], dayKey: String) {
        encode(DeckState(dayKey: dayKey, cards: cards), Key.deck)
    }

    // MARK: - Swipes

    /// Records a swipe: updates the deck card and the passed cooldown. Matched
    /// destinations are stored via `addMatch` by the caller.
    func recordSwipe(cityCode: String, direction: SwipeDirection, now: Date = Date()) {
        if var state = decode(DeckState.self, Key.deck),
           let index = state.cards.firstIndex(where: { $0.destination.city.code == cityCode }) {
            state.cards[index].swipe = direction
            encode(state, Key.deck)
        }

        if direction == .pass {
            var passed = passedMap()
            passed[cityCode] = now
            defaults.set(passed, forKey: Key.passed)
        }
    }

    // MARK: - Daily like budget

    /// Likes used so far today (0 once the day rolls over).
    func likesUsedToday(now: Date = Date()) -> Int {
        guard let state = decode(LikeState.self, Key.likes),
              state.dayKey == Self.dayKey(for: now) else { return 0 }
        return state.count
    }

    /// Likes still available today.
    func likesRemainingToday(now: Date = Date()) -> Int {
        max(0, Self.dailyLikeLimit - likesUsedToday(now: now))
    }

    /// Spends one like from today's budget. Caller is responsible for checking
    /// `likesRemainingToday()` first.
    func recordLike(now: Date = Date()) {
        let key = Self.dayKey(for: now)
        encode(LikeState(dayKey: key, count: likesUsedToday(now: now) + 1), Key.likes)
    }

    // MARK: - Passed cooldown

    func isOnCooldown(cityCode: String, now: Date = Date()) -> Bool {
        guard let date = passedMap()[cityCode] else { return false }
        return now.timeIntervalSince(date) < Self.passedCooldown
    }

    /// City codes still hidden from the deck (passed within the cooldown window).
    func cooldownCityCodes(now: Date = Date()) -> Set<String> {
        Set(passedMap().filter { now.timeIntervalSince($0.value) < Self.passedCooldown }.keys)
    }

    // MARK: - Matches

    func matchedDestinations() -> [Destination] {
        Array(matchedMap().values)
    }

    func matchedCityCodes() -> Set<String> {
        Set(matchedMap().keys)
    }

    func isMatched(cityCode: String) -> Bool {
        matchedMap()[cityCode] != nil
    }

    func addMatch(_ destination: Destination) {
        var matched = matchedMap()
        matched[destination.city.code] = destination
        encode(matched, Key.matched)
    }

    func removeMatch(cityCode: String) {
        var matched = matchedMap()
        matched[cityCode] = nil
        encode(matched, Key.matched)
    }

    // MARK: - Notification de-dupe

    private struct NotifiedRecord: Codable {
        var price: Double
        var date: Date
    }

    /// Whether a match alert (keyed by `key`) is fresh enough to fire: not seen
    /// within the dedupe window, or meaningfully cheaper than last time.
    func shouldNotify(key: String, price: Double, now: Date = Date()) -> Bool {
        let records = decode([String: NotifiedRecord].self, Key.notified) ?? [:]
        guard let last = records[key] else { return true }
        let expired = now.timeIntervalSince(last.date) > Self.dedupeWindow
        let cheaper = price <= last.price * (1 - Self.realertPriceDrop)
        return expired || cheaper
    }

    func recordNotified(key: String, price: Double, now: Date = Date()) {
        var records = decode([String: NotifiedRecord].self, Key.notified) ?? [:]
        records[key] = NotifiedRecord(price: price, date: now)
        records = records.filter { now.timeIntervalSince($0.value.date) <= Self.dedupeWindow }
        encode(records, Key.notified)
    }

    // MARK: - Helpers

    private func passedMap() -> [String: Date] {
        (defaults.dictionary(forKey: Key.passed) as? [String: Date]) ?? [:]
    }

    private func matchedMap() -> [String: Destination] {
        decode([String: Destination].self, Key.matched) ?? [:]
    }

    private func decode<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func encode<T: Encodable>(_ value: T, _ key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }
}
