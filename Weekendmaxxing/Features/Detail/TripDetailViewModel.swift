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

    /// Places to stay for this weekend, cheapest first. Loaded alongside flights;
    /// failures leave this empty so the screen still works as flights-only.
    private(set) var stays: [StayOffer] = []

    let originCode: String
    let destination: Destination

    private let service: TripService
    private let preferences: PreferencesStore

    init(
        service: TripService,
        originCode: String,
        destination: Destination,
        preferences: PreferencesStore = .shared
    ) {
        self.service = service
        self.originCode = originCode
        self.destination = destination
        self.preferences = preferences
    }

    var weekend: WeekendWindow { destination.weekend }

    /// The cheapest stay (by total), if any were found.
    var cheapestStay: StayOffer? { stays.min { $0.total.amount < $1.total.amount } }

    /// The complete package — cheapest flight paired with the cheapest stay.
    var package: WeekendPackage? {
        guard case .loaded(let offers) = state, let flight = offers.first else { return nil }
        return WeekendPackage(flight: flight, stay: cheapestStay)
    }

    func load() async {
        state = .loading
        // Stays load in parallel with flights and never fail the screen.
        async let staysResult: [StayOffer] = (try? await service.stays(
            city: destination.city,
            weekend: destination.weekend,
            types: preferences.preferences.accommodationTypes,
            adults: 1
        )) ?? []
        do {
            let offers = try await service.offers(
                origin: originCode,
                destination: destination.city.code,
                weekend: destination.weekend,
                adults: 1
            )
            stays = await staysResult
            state = offers.isEmpty ? .empty : .loaded(offers)
        } catch {
            stays = await staysResult
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .error(message)
        }
    }
}
