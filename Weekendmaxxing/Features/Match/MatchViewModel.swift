import Foundation
import Observation

/// Drives the daily swipe deck: builds (and persists) the day's picks from the
/// traveller's preferences, and records swipe decisions.
@MainActor
@Observable
final class MatchViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    private(set) var cards: [DeckCard] = []
    private(set) var state: LoadState = .idle
    /// Likes spent today, mirrored from the store so the view updates live.
    private(set) var likesUsedToday = 0

    let usingSampleData = AppConfig.usesMockData
    let dataSourceLabel = AppConfig.dataSourceDescription

    private let service: TripService
    private let store: MatchStore
    private let preferences: PreferencesStore
    private let origin = "LON"

    init(
        service: TripService,
        store: MatchStore = .shared,
        preferences: PreferencesStore = .shared
    ) {
        self.service = service
        self.store = store
        self.preferences = preferences
    }

    /// Cards not yet swiped, top of the deck first.
    var pendingCards: [DeckCard] { cards.filter { !$0.isSwiped } }
    var topCard: DeckCard? { pendingCards.first }

    /// True once today's picks have all been swiped.
    var allSwiped: Bool { state == .loaded && cards.isEmpty == false && pendingCards.isEmpty }
    /// True when the preferences produced no picks at all today.
    var noPicks: Bool { state == .loaded && cards.isEmpty }

    var picksRemaining: Int { pendingCards.count }

    /// The single upcoming weekend the discover deck is scoped to.
    var comingWeekend: WeekendWindow? {
        WeekendCalculator.upcomingWeekends(count: 1, style: preferences.preferences.weekendStyle).first
    }

    /// Daily like budget, surfaced to the view.
    let dailyLikeLimit = MatchStore.dailyLikeLimit
    var likesRemaining: Int { max(0, dailyLikeLimit - likesUsedToday) }
    /// Whether the user can still like (right/up swipe) today.
    var canLike: Bool { likesRemaining > 0 }
    /// True once today's like budget is spent but cards remain to browse.
    var outOfLikes: Bool { state == .loaded && !canLike && !pendingCards.isEmpty }

    var loadingMessage: String { "Finding today's picks…" }

    /// Loads today's deck from storage, generating it if needed.
    func load() async {
        likesUsedToday = store.likesUsedToday()
        let dayKey = MatchStore.dayKey()
        if let saved = store.deck(for: dayKey) {
            cards = saved
            state = .loaded
            return
        }
        await generate(dayKey: dayKey)
    }

    /// Forces a fresh scan for today (used by pull-to-refresh / retry).
    func refresh() async {
        likesUsedToday = store.likesUsedToday()
        await generate(dayKey: MatchStore.dayKey())
    }

    private func generate(dayKey: String) async {
        state = .loading
        let prefs = preferences.preferences
        // Discover is scoped to the single coming weekend so the deck always
        // headlines the nearest escape rather than fares spread months out.
        let windows = WeekendCalculator.upcomingWeekends(count: 1, style: prefs.weekendStyle)
        do {
            let results = try await service.cheapestDestinations(
                origin: origin,
                maxPrice: prefs.maxPriceParam,
                weekends: windows
            )
            let excluded = store.matchedCityCodes().union(store.cooldownCityCodes())
            let picks = Array(
                results
                    .filter { prefs.matches(city: $0.city) }
                    .filter { !excluded.contains($0.city.code) }
                    .prefix(MatchStore.deckSize)
            )
            // Enrich each pick with its cheapest stay so the card can headline a
            // complete package price (flights + stay).
            let enriched = await enrichWithStays(picks, types: prefs.accommodationTypes)
            let deck = enriched.map { DeckCard(destination: $0, swipe: nil) }
            store.saveDeck(deck, dayKey: dayKey)
            cards = deck
            state = .loaded
        } catch {
            state = .error((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    /// Fetches the cheapest stay for each destination (bounded concurrency) and
    /// folds its total into `Destination.stayFrom`. Per-card failures leave that
    /// destination as flights-only — `cheapestStay` already swallows errors.
    private func enrichWithStays(
        _ destinations: [Destination],
        types: Set<AccommodationType>
    ) async -> [Destination] {
        let service = self.service
        var result = destinations
        for batch in Array(destinations.enumerated()).chunked(into: 4) {
            await withTaskGroup(of: (Int, Price?).self) { group in
                for (index, destination) in batch {
                    group.addTask {
                        let stay = await service.cheapestStay(
                            city: destination.city,
                            weekend: destination.weekend,
                            types: types
                        )
                        return (index, stay?.total)
                    }
                }
                for await (index, total) in group { result[index].stayFrom = total }
            }
        }
        return result
    }

    /// Records a swipe on the top card and persists it. Returns the swiped card
    /// so the view can also save matches to SwiftData.
    @discardableResult
    func swipe(_ direction: SwipeDirection) -> DeckCard? {
        guard let card = topCard else { return nil }
        // A like (match / super-match) costs one from today's budget; passes are free.
        if direction != .pass && !canLike { return nil }

        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index].swipe = direction
        }
        store.recordSwipe(cityCode: card.destination.city.code, direction: direction)
        if direction != .pass {
            store.addMatch(card.destination)
            store.recordLike()
            likesUsedToday += 1
        }
        return card
    }
}
