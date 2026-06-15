import Foundation
import Observation

/// Loads the concrete offers for a discovered destination + weekend.
@MainActor
@Observable
final class TripDetailViewModel {
    enum ViewState {
        case loading
        case loaded([TripOffer])
        case empty
        case error(String)
    }

    var state: ViewState = .loading

    let originCode: String
    let destination: Destination

    private let service: TripService

    init(service: TripService, originCode: String, destination: Destination) {
        self.service = service
        self.originCode = originCode
        self.destination = destination
    }

    var weekend: WeekendWindow { destination.weekend }

    func load() async {
        state = .loading
        do {
            let offers = try await service.offers(
                origin: originCode,
                destination: destination.city.code,
                weekend: destination.weekend,
                adults: 1
            )
            state = offers.isEmpty ? .empty : .loaded(offers)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .error(message)
        }
    }
}
