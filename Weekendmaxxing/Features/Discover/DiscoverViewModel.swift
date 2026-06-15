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

    // Controls
    var origin: Airport = .londonAll
    var weekendStyle: WeekendStyle = .fridayToSunday {
        didSet { regenerateWeekends() }
    }
    var weekends: [WeekendWindow] = []
    var selectedWeekendIndex: Int = 0
    /// 50...500; 500 is treated as "Any budget".
    var maxBudget: Double = 200

    // State
    var state: ViewState = .idle

    let usingSampleData = AppConfig.usesMockData
    let dataSourceLabel = AppConfig.dataSourceDescription

    private let service: TripService

    init(service: TripService) {
        self.service = service
        regenerateWeekends()
    }

    var selectedWeekend: WeekendWindow? { weekends[safe: selectedWeekendIndex] }

    var maxPriceParam: Int? { maxBudget >= 500 ? nil : Int(maxBudget) }

    var budgetLabel: String {
        maxBudget >= 500 ? "Any budget" : "Under \(CurrencyFormatter.string(amount: maxBudget, currency: "GBP", fractionDigits: 0))"
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
        if selectedWeekendIndex >= weekends.count { selectedWeekendIndex = 0 }
    }

    func selectWeekend(_ index: Int) {
        selectedWeekendIndex = index
    }

    func load() async {
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
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .error(message)
        }
    }
}
