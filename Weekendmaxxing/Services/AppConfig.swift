import Foundation

/// Reads configuration injected from `Config/Secrets.xcconfig` via Info.plist
/// and decides which `TripService` implementation to use.
enum AppConfig {
    /// Travelpayouts (Aviasales) Data API token. Leave blank to force mock data.
    static var travelpayoutsToken: String? { nonEmpty(infoString("TravelpayoutsToken")) }

    /// Optional affiliate marker used to build commissionable booking links.
    static var travelpayoutsMarker: String? { nonEmpty(infoString("TravelpayoutsMarker")) }

    /// Optional SerpApi key. When present, the live Google Flights source powers
    /// the Search / offers screen (Travelpayouts still powers discovery).
    static var serpApiKey: String? { nonEmpty(infoString("SerpApiKey")) }

    /// The `USE_MOCK` build flag (defaults to mock when unset).
    static var useMockFlag: Bool { infoBool("UseMockData", default: true) }

    static var hasCredentials: Bool { travelpayoutsToken != nil }

    /// We fall back to mock data when explicitly requested or when no token exists.
    static var usesMockData: Bool { useMockFlag || !hasCredentials }

    /// A short, human-readable description of the active data source (for UI).
    static var dataSourceDescription: String {
        usesMockData ? "Sample data" : "Live · Travelpayouts"
    }

    /// Builds the trip service for the app. Discovery uses Travelpayouts (with a
    /// mock fallback). When a SerpApi key is present, offers use live Google
    /// Flights (falling back to Travelpayouts, then mock).
    static func makeTripService() -> TripService {
        let mock = MockTripService()
        guard !usesMockData, let token = travelpayoutsToken else {
            return mock
        }
        let travelpayouts = TravelpayoutsTripService(token: token, marker: travelpayoutsMarker)
        let travelpayoutsWithMock = FallbackTripService(primary: travelpayouts, fallback: mock)

        guard let serpKey = serpApiKey else {
            return travelpayoutsWithMock
        }
        let serp = SerpApiTripService(apiKey: serpKey)
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
