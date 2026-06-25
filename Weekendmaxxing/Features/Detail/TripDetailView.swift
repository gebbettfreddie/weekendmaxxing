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
                packageSummary
                offers
                staysSection
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
            DestinationBanner(city: destination.city, height: 180)
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
                if let source = list.dataSource, source.isApproximate {
                    OfferSourceNote(source: source)
                }
                ForEach(list) { offer in
                    NavigationLink(value: offer) {
                        OfferRow(offer: offer)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Package summary

    @ViewBuilder
    private var packageSummary: some View {
        if let package = model.package, let stay = package.stay {
            VStack(alignment: .leading, spacing: 12) {
                Text("Weekend package")
                    .font(.title3.weight(.bold))

                lineItem(icon: "airplane", title: "Return flights", value: package.flight.price.formattedRounded)
                lineItem(
                    icon: stay.type.systemImage,
                    title: "\(stay.nights) nights · \(stay.type.title)",
                    value: stay.total.formattedRounded
                )

                Divider()

                HStack {
                    Text("Total for the weekend")
                        .font(.headline)
                    Spacer()
                    Text(package.total.formattedRounded)
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(Brand.coral)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }

    private func lineItem(icon: String, title: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }

    // MARK: - Stays

    @ViewBuilder
    private var staysSection: some View {
        if !model.stays.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Where to stay")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let source = model.stays.first?.source, source.isApproximate {
                    OfferSourceNote(source: source)
                }

                ForEach(model.stays) { stay in
                    StayRow(stay: stay)
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

/// A single accommodation option in the "Where to stay" list.
private struct StayRow: View {
    let stay: StayOffer

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: stay.type.systemImage)
                .font(.title3)
                .foregroundStyle(Brand.coral)
                .frame(width: 42, height: 42)
                .background(Brand.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(stay.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Text(stay.type.title)
                    if let area = stay.area { Text("· \(area)") }
                    if let rating = stay.rating {
                        Text("· ★ \(String(format: "%.1f", rating))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 0) {
                Text(stay.pricePerNight.formattedRounded)
                    .font(.subheadline.weight(.bold))
                Text("per night")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
