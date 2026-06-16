import Foundation

/// Persists deal-alert settings, the de-dupe cache, and the recent-deals list in
/// `UserDefaults` so the foreground UI and the background task share state.
final class DealStore: @unchecked Sendable {
    static let shared = DealStore()

    private let defaults: UserDefaults

    private enum Key {
        static let enabled = "deals.enabled"
        static let maxBudget = "deals.maxBudget"
        static let notified = "deals.notified"   // [dealID: NotifiedRecord]
        static let recent = "deals.recent"       // [Deal]
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Settings

    var alertsEnabled: Bool {
        get { defaults.bool(forKey: Key.enabled) }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    var maxBudget: Double {
        get {
            let value = defaults.double(forKey: Key.maxBudget)
            return value == 0 ? DealRules.defaultMaxBudget : value
        }
        set { defaults.set(newValue, forKey: Key.maxBudget) }
    }

    // MARK: - Recent deals (for the Alerts tab)

    func recentDeals() -> [Deal] {
        decode([Deal].self, Key.recent) ?? []
    }

    /// Merges freshly found deals into the recent list (newest first, deduped by id).
    func mergeRecent(_ deals: [Deal]) {
        var existing = recentDeals()
        let ids = Set(deals.map(\.id))
        existing.removeAll { ids.contains($0.id) }
        let merged = (deals + existing).sorted { $0.foundAt > $1.foundAt }
        encode(Array(merged.prefix(DealRules.recentDealsLimit)), Key.recent)
    }

    // MARK: - Notification de-dupe

    private struct NotifiedRecord: Codable {
        var price: Double
        var date: Date
    }

    /// Whether this deal is fresh enough to notify: not seen within the dedupe
    /// window, or meaningfully cheaper than the last time we alerted on it.
    func shouldNotify(_ deal: Deal, now: Date = Date()) -> Bool {
        let records = decode([String: NotifiedRecord].self, Key.notified) ?? [:]
        guard let last = records[deal.id] else { return true }
        let expired = now.timeIntervalSince(last.date) > DealRules.dedupeWindow
        let cheaper = deal.price.amount <= last.price * (1 - DealRules.realertPriceDrop)
        return expired || cheaper
    }

    /// Records that we notified about these deals (and prunes expired entries).
    func recordNotified(_ deals: [Deal], now: Date = Date()) {
        var records = decode([String: NotifiedRecord].self, Key.notified) ?? [:]
        for deal in deals {
            records[deal.id] = NotifiedRecord(price: deal.price.amount, date: now)
        }
        records = records.filter { now.timeIntervalSince($0.value.date) <= DealRules.dedupeWindow }
        encode(records, Key.notified)
    }

    // MARK: - Codable helpers

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
