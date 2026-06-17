import Foundation
import Observation

/// Tracks how many live flight-data API requests the app makes, so the user can
/// keep an eye on usage against the providers' (limited) free quotas.
///
/// Counts are split per provider and per calendar month — the window most free
/// tiers reset on — and persisted in `UserDefaults` so they survive launches and
/// are shared between the foreground UI and the background deal-scan task.
@MainActor
@Observable
final class APIUsageTracker {
    static let shared = APIUsageTracker()

    /// The live data sources whose requests we count.
    enum Provider: String, CaseIterable, Identifiable {
        case travelpayouts
        case proxy

        var id: String { rawValue }

        var title: String {
            switch self {
            case .travelpayouts: return "Travelpayouts"
            case .proxy: return "Flight proxy"
            }
        }
    }

    private let defaults: UserDefaults

    private enum Key {
        static let total = "apiUsage.total"      // [providerRaw: lifetime count]
        static let month = "apiUsage.month"      // [providerRaw: count this month]
        static let monthKey = "apiUsage.monthKey" // "yyyy-MM" the month counts belong to
        static let last = "apiUsage.lastRequest" // Date of the most recent request
    }

    private(set) var totalByProvider: [String: Int]
    private(set) var monthByProvider: [String: Int]
    private(set) var monthKey: String
    private(set) var lastRequestDate: Date?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.totalByProvider = defaults.dictionary(forKey: Key.total) as? [String: Int] ?? [:]
        self.monthByProvider = defaults.dictionary(forKey: Key.month) as? [String: Int] ?? [:]
        self.monthKey = defaults.string(forKey: Key.monthKey) ?? Self.monthKey(for: Date())
        self.lastRequestDate = defaults.object(forKey: Key.last) as? Date
        rolloverIfNeeded()
    }

    // MARK: - Reads

    var totalThisMonth: Int { monthByProvider.values.reduce(0, +) }
    var totalAllTime: Int { totalByProvider.values.reduce(0, +) }

    func thisMonth(for provider: Provider) -> Int { monthByProvider[provider.rawValue] ?? 0 }
    func allTime(for provider: Provider) -> Int { totalByProvider[provider.rawValue] ?? 0 }

    // MARK: - Writes

    /// Records a single outgoing request to `provider`.
    func record(_ provider: Provider, at date: Date = Date()) {
        rolloverIfNeeded(now: date)
        totalByProvider[provider.rawValue, default: 0] += 1
        monthByProvider[provider.rawValue, default: 0] += 1
        lastRequestDate = date
        persist()
    }

    /// Clears all recorded usage.
    func reset() {
        totalByProvider = [:]
        monthByProvider = [:]
        monthKey = Self.monthKey(for: Date())
        lastRequestDate = nil
        persist()
    }

    // MARK: - Helpers

    /// Wipes the monthly counts when the calendar month changes.
    private func rolloverIfNeeded(now: Date = Date()) {
        let current = Self.monthKey(for: now)
        guard current != monthKey else { return }
        monthKey = current
        monthByProvider = [:]
        persist()
    }

    private func persist() {
        defaults.set(totalByProvider, forKey: Key.total)
        defaults.set(monthByProvider, forKey: Key.month)
        defaults.set(monthKey, forKey: Key.monthKey)
        defaults.set(lastRequestDate, forKey: Key.last)
    }

    private static func monthKey(for date: Date) -> String {
        monthFormatter.string(from: date)
    }

    private static let monthFormatter = AppTime.dateFormatter("yyyy-MM")
}
