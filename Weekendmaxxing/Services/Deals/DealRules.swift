import Foundation

/// Single source of truth for what counts as a "super cheap" deal, plus the
/// background-scan tuning constants. Kept free of UI/IO so it is easy to reason
/// about and test.
enum DealRules {
    /// Background task identifier (must match Info.plist `BGTaskSchedulerPermittedIdentifiers`).
    static let taskIdentifier = "com.weekendmaxxing.app.dealcheck"

    /// Minimum discount vs the route's typical price to qualify (0.35 = 35% off).
    static let discountThreshold = 0.35
    /// How many upcoming weekends to scan each run.
    static let weekendsToScan = 6
    /// Max notifications fired per run (avoid spamming).
    static let maxNotificationsPerRun = 3
    /// Don't re-notify the same route+weekend within this window…
    static let dedupeWindow: TimeInterval = 7 * 24 * 60 * 60
    /// …unless the price has dropped at least this much below the last alert.
    static let realertPriceDrop = 0.10
    /// How many recent deals to keep for the Alerts tab.
    static let recentDealsLimit = 30

    /// Default and bounds for the user's budget cap.
    static let defaultMaxBudget = 150.0
    static let minBudget = 40.0
    static let maxBudget = 300.0

    /// The hybrid rule: a big discount vs typical AND under the user's budget.
    static func isDeal(price: Double, baseline: Double, maxBudget: Double) -> Bool {
        guard baseline > 0 else { return false }
        let savings = 1 - price / baseline
        return savings >= discountThreshold && price <= maxBudget
    }
}
