import SwiftUI
import SwiftData

/// Navigation route for opening a saved trip's detail.
enum SavedRoute: Hashable {
    case offer(TripOffer, WeekendWindow)
    case destination(Destination)
}

struct SavedView: View {
    let service: TripService

    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Query(sort: \SavedTrip.savedAt, order: .reverse) private var savedTrips: [SavedTrip]
    @State private var path: [SavedRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if savedTrips.isEmpty {
                    EmptyStateView(
                        systemImage: "heart",
                        title: "No matches yet",
                        message: "Swipe right on a destination in Match to keep it here and we'll watch its price for you."
                    )
                } else {
                    List {
                        ForEach(savedTrips) { trip in
                            NavigationLink(value: route(for: trip)) {
                                SavedTripRow(trip: trip)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Matches")
            .toolbar {
                if !savedTrips.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) { EditButton() }
                }
            }
            .navigationDestination(for: SavedRoute.self) { route in
                switch route {
                case .offer(let offer, let weekend):
                    OfferDetailView(offer: offer, weekend: weekend)
                case .destination(let destination):
                    TripDetailView(service: service, originCode: "LON", destination: destination)
                }
            }
        }
        .onChange(of: router.pendingMatchDestination) { _, destination in
            guard let destination else { return }
            path = [.destination(destination)]
            router.pendingMatchDestination = nil
        }
    }

    private func route(for trip: SavedTrip) -> SavedRoute {
        if let offer = trip.decodedOffer {
            return .offer(offer, trip.weekend)
        }
        let city = City(
            code: trip.cityCode,
            name: trip.cityName,
            country: trip.country,
            countryCode: trip.countryCode,
            basePrice: 0
        )
        return .destination(
            Destination(city: city, price: trip.price, weekend: trip.weekend)
        )
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedTrips[index])
        }
        try? modelContext.save()
    }
}

private struct SavedTripRow: View {
    let trip: SavedTrip

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                LinearGradient.forDestination(trip.cityCode)
                Text(trip.flagEmoji)
                    .font(.title2)
            }
            .frame(width: 54, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(trip.cityName)
                    .font(.headline)
                Text(DateUtil.weekendLabel(trip.weekend))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    InfoChip(
                        systemImage: trip.isOffer ? "airplane" : "mappin",
                        text: trip.isOffer ? (trip.airline ?? "Flight") : "Destination"
                    )
                    if trip.isOffer && trip.isDirect {
                        InfoChip(systemImage: "arrow.right", text: "Direct")
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                Text(trip.price.formattedRounded)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Brand.coral)
                Text(trip.isOffer ? "return" : "from")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .cardStyle()
    }
}
