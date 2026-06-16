import Foundation

/// Resolves a real city photo at runtime for any destination that doesn't ship
/// with a curated image (the long tail of live API results). It uses Wikipedia's
/// `pageimages` API - the same source as the bundled catalog photos - and caches
/// each result in memory and `UserDefaults`, so a city is fetched at most once.
actor CityImageResolver {
    static let shared = CityImageResolver()

    private var cache: [String: String]   // normalized name -> URL string ("" = no image)
    private let defaults: UserDefaults
    private let session: URLSession
    private let cacheKey = "cityImageCache.v1"

    init(defaults: UserDefaults = .standard, session: URLSession = .shared) {
        self.defaults = defaults
        self.session = session
        self.cache = (defaults.dictionary(forKey: "cityImageCache.v1") as? [String: String]) ?? [:]
    }

    /// A photo URL for the city. Prefers a baked/curated image, otherwise the
    /// Wikipedia lead image. Returns nil for placeholder cities (code only).
    func imageURL(for city: City) async -> URL? {
        if let baked = city.imageURL { return baked }

        let name = city.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.uppercased() != city.code.uppercased() else { return nil }

        let key = name.lowercased()
        if let cached = cache[key] {
            return cached.isEmpty ? nil : URL(string: cached)
        }

        let resolved = await fetchLeadImage(title: name)
        cache[key] = resolved ?? ""
        defaults.set(cache, forKey: cacheKey)
        return resolved.flatMap(URL.init)
    }

    private func fetchLeadImage(title: String) async -> String? {
        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")
        components?.queryItems = [
            .init(name: "action", value: "query"),
            .init(name: "prop", value: "pageimages"),
            .init(name: "format", value: "json"),
            .init(name: "pithumbsize", value: "1024"),
            .init(name: "redirects", value: "1"),
            .init(name: "titles", value: title)
        ]
        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue(
            "WeekendmaxxingApp/1.0 (https://gebbettfreddie.github.io/weekendmaxxing/)",
            forHTTPHeaderField: "User-Agent"
        )
        request.timeoutInterval = 15

        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }
        return Self.parseThumbnail(data)
    }

    private static func parseThumbnail(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let query = json["query"] as? [String: Any],
              let pages = query["pages"] as? [String: Any] else {
            return nil
        }
        for case let page as [String: Any] in pages.values {
            if let thumbnail = page["thumbnail"] as? [String: Any],
               let source = thumbnail["source"] as? String {
                return source
            }
        }
        return nil
    }
}
