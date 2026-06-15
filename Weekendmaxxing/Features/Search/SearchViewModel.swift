import Foundation
import Observation

enum OfferSort: String, CaseIterable, Identifiable {
    case price
    case duration
    case departure

    var id: String { rawValue }
    var title: String {
        switch self {
        case .price: return "Cheapest"
        case .duration: return "Fastest"
        case .departure: return "Earliest"
        }
    }
}

@MainActor
@Observable
final class SearchViewModel {
    enum ViewState {
        case idle
        case loading
        case loaded([TripOffer])
        case empty
        case error(String)
    }

    var state: ViewState = .idle

    var origin: Airport = .londonAll
    var selectedCity: City?
    var weekendStyle: WeekendStyle = .fridayToSunday {
        didSet { regenerateWeekends() }
    }
    var weekends: [WeekendWindow] = []
    var selectedWeekendIndex: Int = 0
    var sort: OfferSort = .price {
        didSet { applySort() }
    }

    let cities = CityCatalog.shared.cities
    let usingSampleData = AppConfig.usesMockData

    private let service: TripService

    init(service: TripService) {
        self.service = service
        regenerateWeekends()
    }

    var selectedWeekend: WeekendWindow? { weekends[safe: selectedWeekendIndex] }
    var canSearch: Bool { selectedCity != nil && selectedWeekend != nil }

    func weekendTitle(_ index: Int) -> String {
        guard let window = weekends[safe: index] else { return "" }
        return DateUtil.relativeWeekendLabel(window, index: index)
    }

    func regenerateWeekends() {
        weekends = WeekendCalculator.upcomingWeekends(count: 6, style: weekendStyle)
        if selectedWeekendIndex >= weekends.count { selectedWeekendIndex = 0 }
    }

    func search() async {
        guard let city = selectedCity, let weekend = selectedWeekend else {
            state = .idle
            return
        }
        state = .loading
        do {
            let offers = try await service.offers(
                origin: origin.code,
                destination: city.code,
                weekend: weekend,
                adults: 1
            )
            state = offers.isEmpty ? .empty : .loaded(sorted(offers))
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .error(message)
        }
    }

    private func applySort() {
        if case .loaded(let offers) = state {
            state = .loaded(sorted(offers))
        }
    }

    private func sorted(_ offers: [TripOffer]) -> [TripOffer] {
        switch sort {
        case .price:
            return offers.sorted { $0.price.amount < $1.price.amount }
        case .duration:
            return offers.sorted { $0.totalDurationMinutes < $1.totalDurationMinutes }
        case .departure:
            return offers.sorted {
                ($0.outbound.departure ?? .distantFuture) < ($1.outbound.departure ?? .distantFuture)
            }
        }
    }
}
