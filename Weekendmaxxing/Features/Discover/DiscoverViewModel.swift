import Foundation
import Observation

@MainActor
@Observable
final class DiscoverViewModel {
    enum ViewState {
        case idle
        case loading
        case loaded([Destination])
        case empty
        case error(String)
    }

    /// What the user is currently browsing: either the cheapest fares across a
    /// wide horizon, or a single specific weekend.
    enum Selection: Equatable {
        case bestPrice
        case weekend(Int)
    }

    // Controls
    var origin: Airport = .londonAll
    var weekendStyle: WeekendStyle = .fridayToSunday {
        didSet { regenerateWeekends() }
    }
    var weekends: [WeekendWindow] = []
    /// Defaults to the cheapest trip across the next few months.
    var selection: Selection = .bestPrice
    /// How far ahead the "Best price" scan looks.
    let bestPriceMonths = 3
    /// 50...500; 500 is treated as "Any budget".
    var maxBudget: Double = 200

    // State
    var state: ViewState = .idle

    let usingSampleData = AppConfig.usesMockData
    let dataSourceLabel = AppConfig.dataSourceDescription

    private let service: TripService

    init(service: TripService, preferences: PreferencesStore = .shared) {
        self.service = service
        let prefs = preferences.preferences
        self.maxBudget = prefs.maxBudget
        self.weekendStyle = prefs.weekendStyle
        regenerateWeekends()
    }

    var selectedWeekend: WeekendWindow? {
        guard case .weekend(let index) = selection else { return nil }
        return weekends[safe: index]
    }

    var isBestPriceSelected: Bool { selection == .bestPrice }

    var maxPriceParam: Int? { maxBudget >= 500 ? nil : Int(maxBudget) }

    var budgetLabel: String {
        maxBudget >= 500 ? "Any budget" : "Under \(CurrencyFormatter.string(amount: maxBudget, currency: "GBP", fractionDigits: 0))"
    }

    var bestPriceTitle: String { "Best price" }
    var bestPriceSubtitle: String { "Next \(bestPriceMonths) months" }

    var loadingMessage: String {
        isBestPriceSelected
            ? "Comparing the next \(bestPriceMonths) months for the cheapest weekends…"
            : "Finding the cheapest escapes…"
    }

    func weekendTitle(_ index: Int) -> String {
        guard let window = weekends[safe: index] else { return "" }
        return DateUtil.relativeWeekendLabel(window, index: index)
    }

    func weekendSubtitle(_ index: Int) -> String? {
        guard let window = weekends[safe: index], index < 2 else { return nil }
        return DateUtil.weekendLabel(window)
    }

    func regenerateWeekends() {
        weekends = WeekendCalculator.upcomingWeekends(count: 6, style: weekendStyle)
        if case .weekend(let index) = selection, index >= weekends.count {
            selection = .weekend(0)
        }
    }

    func selectBestPrice() {
        selection = .bestPrice
    }

    func selectWeekend(_ index: Int) {
        selection = .weekend(index)
    }

    func load() async {
        switch selection {
        case .bestPrice:
            await loadBestPrice()
        case .weekend:
            await loadSelectedWeekend()
        }
    }

    private func loadSelectedWeekend() async {
        guard let weekend = selectedWeekend else { return }
        state = .loading
        do {
            let results = try await service.cheapestDestinations(
                origin: origin.code,
                maxPrice: maxPriceParam,
                weekend: weekend
            )
            state = results.isEmpty ? .empty : .loaded(results)
        } catch {
            state = .error(errorMessage(error))
        }
    }

    private func loadBestPrice() async {
        state = .loading
        let windows = WeekendCalculator.upcomingWeekends(months: bestPriceMonths, style: weekendStyle)
        do {
            let results = try await service.cheapestDestinations(
                origin: origin.code,
                maxPrice: maxPriceParam,
                weekends: windows
            )
            state = results.isEmpty ? .empty : .loaded(results)
        } catch {
            state = .error(errorMessage(error))
        }
    }

    private func errorMessage(_ error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
