import SwiftUI
import SwiftData

/// Destination-level detail: a header for the city/weekend and the list of
/// concrete flight offers. Tapping an offer opens the full offer breakdown.
struct TripDetailView: View {
    @State private var model: TripDetailViewModel
    @State private var loadTask: Task<Void, Never>?
    @State private var isSaved = false

    @Environment(\.modelContext) private var modelContext

    init(service: TripService, originCode: String, destination: Destination) {
        _model = State(initialValue: TripDetailViewModel(
            service: service, originCode: originCode, destination: destination
        ))
    }

    private var destination: Destination { model.destination }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                offers
            }
            .padding(.horizontal)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(destination.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isSaved = SavedTripsStore.isSaved(id: savedTrip.id, context: modelContext)
            await model.load()
        }
        .navigationDestination(for: TripOffer.self) { offer in
            OfferDetailView(offer: offer, weekend: model.weekend)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            DestinationBanner(
                code: destination.city.code,
                flagEmoji: destination.flagEmoji,
                imageURL: destination.city.imageURL,
                height: 180
            )
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(destination.name)
                        .font(.largeTitle.weight(.heavy))
                    Text(destination.country)
                        .font(.subheadline.weight(.medium))
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
                .padding(16)
            }

            VStack(spacing: 14) {
                HStack {
                    Label(DateUtil.weekendLabel(destination.weekend), systemImage: "calendar")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text("\(destination.weekend.nights) nights")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button(action: toggleSave) {
                    Label(
                        isSaved ? "Saved" : "Save destination",
                        systemImage: isSaved ? "bookmark.fill" : "bookmark"
                    )
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Brand.coral)
            }
            .padding(16)
        }
        .cardStyle()
    }

    // MARK: - Offers

    @ViewBuilder
    private var offers: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Flights")
                .font(.title3.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            switch model.state {
            case .loading:
                LoadingView(message: "Loading flights to \(destination.name)…")
            case .empty:
                EmptyStateView(
                    systemImage: "airplane",
                    title: "No flights found",
                    message: "We couldn't find offers for this weekend. Try another date from Discover."
                )
            case .error(let message):
                ErrorStateView(message: message) { reload() }
            case .loaded(let list):
                ForEach(list) { offer in
                    NavigationLink(value: offer) {
                        OfferRow(offer: offer)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Actions

    private var savedTrip: SavedTrip { SavedTrip(destination: destination) }

    private func toggleSave() {
        isSaved = SavedTripsStore.toggle(savedTrip, context: modelContext)
    }

    private func reload() {
        loadTask?.cancel()
        loadTask = Task { await model.load() }
    }
}
