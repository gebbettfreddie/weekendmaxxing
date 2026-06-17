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

    let usingSampleData = AppConfig.usesMockData
    let dataSourceLabel = AppConfig.dataSourceDescription

    private let service: TripService
    private let store: MatchStore
    private let preferences: PreferencesStore
    private let origin = "LON"
    private let monthsAhead = 3

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

    var loadingMessage: String { "Finding today's picks…" }

    /// Loads today's deck from storage, generating it if needed.
    func load() async {
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
        await generate(dayKey: MatchStore.dayKey())
    }

    private func generate(dayKey: String) async {
        state = .loading
        let prefs = preferences.preferences
        let windows = WeekendCalculator.upcomingWeekends(months: monthsAhead, style: prefs.weekendStyle)
        do {
            let results = try await service.cheapestDestinations(
                origin: origin,
                maxPrice: prefs.maxPriceParam,
                weekends: windows
            )
            let excluded = store.matchedCityCodes().union(store.cooldownCityCodes())
            let picks = results
                .filter { prefs.matches(city: $0.city) }
                .filter { !excluded.contains($0.city.code) }
                .prefix(MatchStore.dailyPickCount)
            let deck = picks.map { DeckCard(destination: $0, swipe: nil) }
            store.saveDeck(deck, dayKey: dayKey)
            cards = deck
            state = .loaded
        } catch {
            state = .error((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    /// Records a swipe on the top card and persists it. Returns the swiped card
    /// so the view can also save matches to SwiftData.
    @discardableResult
    func swipe(_ direction: SwipeDirection) -> DeckCard? {
        guard let card = topCard else { return nil }
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index].swipe = direction
        }
        store.recordSwipe(cityCode: card.destination.city.code, direction: direction)
        if direction != .pass {
            store.addMatch(card.destination)
        }
        return card
    }
}
