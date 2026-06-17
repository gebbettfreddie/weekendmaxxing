import Foundation

/// Reads configuration injected from `Config/Secrets.xcconfig` via Info.plist
/// and decides which `TripService` implementation to use.
enum AppConfig {
    /// Travelpayouts (Aviasales) Data API token. Leave blank to force mock data.
    static var travelpayoutsToken: String? { nonEmpty(infoString("TravelpayoutsToken")) }

    /// Optional affiliate marker used to build commissionable booking links.
    static var travelpayoutsMarker: String? { nonEmpty(infoString("TravelpayoutsMarker")) }

    /// Base URL of the flight proxy (Cloudflare Worker) that fronts SerpApi with
    /// a shared cache. When present, live Google Flights data powers discovery
    /// and offers. The SerpApi key lives on the proxy, not in the app.
    ///
    /// Stored as a host (no scheme) in `Config/Secrets.xcconfig` because xcconfig
    /// treats `//` as a comment; we prepend `https://` here.
    static var proxyBaseURL: URL? {
        guard let host = nonEmpty(infoString("ProxyHost")) else { return nil }
        let raw = host.hasPrefix("http") ? host : "https://\(host)"
        return URL(string: raw)
    }

    /// Shared token the app sends to the proxy (matches the Worker's APP_TOKEN).
    static var proxyAppToken: String? { nonEmpty(infoString("ProxyAppToken")) }

    /// The `USE_MOCK` build flag (defaults to mock when unset).
    static var useMockFlag: Bool { infoBool("UseMockData", default: true) }

    static var hasCredentials: Bool { travelpayoutsToken != nil }

    /// We fall back to mock data when explicitly requested or when no token exists.
    static var usesMockData: Bool { useMockFlag || !hasCredentials }

    /// A short, human-readable description of the active data source (for UI).
    static var dataSourceDescription: String {
        usesMockData ? "Sample data" : "Live · Travelpayouts"
    }

    /// Builds the trip service. Discovery uses Travelpayouts (with a mock
    /// fallback). When the proxy is configured, offers use live Google Flights
    /// (via the cached proxy), falling back to Travelpayouts then mock.
    static func makeTripService() -> TripService {
        let mock = MockTripService()
        guard !usesMockData, let token = travelpayoutsToken else {
            return mock
        }
        let travelpayouts = TravelpayoutsTripService(token: token, marker: travelpayoutsMarker)
        let travelpayoutsWithMock = FallbackTripService(primary: travelpayouts, fallback: mock)

        guard let proxy = proxyBaseURL else {
            return travelpayoutsWithMock
        }
        let serp = SerpApiTripService(baseURL: proxy, appToken: proxyAppToken ?? "")
        let offers = FallbackTripService(primary: serp, fallback: travelpayoutsWithMock)
        return HybridTripService(discovery: travelpayoutsWithMock, offersProvider: offers)
    }

    // MARK: - Info.plist helpers

    private static func infoString(_ key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }

    private static func infoBool(_ key: String, default defaultValue: Bool) -> Bool {
        guard let raw = infoString(key)?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            return defaultValue
        }
        switch raw {
        case "yes", "true", "1": return true
        case "no", "false", "0": return false
        default: return defaultValue
        }
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
