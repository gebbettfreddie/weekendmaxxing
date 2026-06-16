import SwiftUI
import SwiftData

/// Full breakdown of a single round-trip offer: price, both itineraries with
/// every segment, plus save and book-out actions.
struct OfferDetailView: View {
    let offer: TripOffer
    let weekend: WeekendWindow

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @State private var isSaved = false

    private var city: City {
        offer.destinationCity ?? CityCatalog.shared.cityOrPlaceholder(forCode: offer.outbound.destination ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                summary
                if offer.source.isApproximate {
                    OfferSourceNote(source: offer.source)
                }
                ItineraryCard(title: "Outbound", date: weekend.departureDate, itinerary: offer.outbound)
                if let inbound = offer.inbound {
                    ItineraryCard(title: "Return", date: weekend.returnDate, itinerary: inbound)
                }
                actions
            }
            .padding(.horizontal)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("\(city.name) trip")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isSaved = SavedTripsStore.isSaved(id: savedTrip.id, context: modelContext)
        }
    }

    // MARK: - Header

    private var header: some View {
        DestinationBanner(city: city, height: 150)
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text(city.name)
                    .font(.title.weight(.heavy))
                Text(DateUtil.weekendLabel(weekend))
                    .font(.subheadline.weight(.medium))
                    .opacity(0.9)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Summary

    private var summary: some View {
        HStack(spacing: 14) {
            AirlineAvatar(code: offer.validatingAirline)
            VStack(alignment: .leading, spacing: 4) {
                Text(offer.airlineDisplay)
                    .font(.headline)
                HStack(spacing: 6) {
                    InfoChip(systemImage: offer.isDirect ? "arrow.right" : "arrow.triangle.swap",
                             text: offer.isDirect ? "Direct" : "1+ stop")
                    InfoChip(systemImage: "clock", text: DateUtil.duration(minutes: offer.totalDurationMinutes))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text(offer.price.formatted)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Brand.coral)
                Text("return · 1 adult")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 12) {
            Button(action: toggleSave) {
                Label(isSaved ? "Saved" : "Save trip",
                      systemImage: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(Brand.coral)
            .controlSize(.large)

            if let url = offer.bookingURL {
                Button {
                    openURL(url)
                } label: {
                    Label("Find this trip to book", systemImage: "arrow.up.right.square")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.coral)
                .controlSize(.large)
            }

            Text("Prices and availability are indicative. You'll complete booking on the airline or a partner site.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
    }

    private var savedTrip: SavedTrip { SavedTrip(offer: offer, weekend: weekend) }

    private func toggleSave() {
        isSaved = SavedTripsStore.toggle(savedTrip, context: modelContext)
    }
}

/// One itinerary (a direction) rendered as a vertical timeline of segments
/// with layovers between them.
struct ItineraryCard: View {
    let title: String
    let date: Date
    let itinerary: Itinerary

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(DateUtil.dayMonth(date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(itinerary.segments.enumerated()), id: \.element.id) { index, segment in
                SegmentView(segment: segment)
                if index < itinerary.segments.count - 1 {
                    LayoverView(
                        from: segment.arrival,
                        to: itinerary.segments[index + 1].departure,
                        airport: segment.destination
                    )
                }
            }

            HStack {
                Image(systemName: "clock")
                Text("Total \(DateUtil.duration(minutes: itinerary.durationMinutes)) · \(itinerary.stopsLabel)")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)

            if itinerary.stops > 0 && itinerary.segments.count <= 1 {
                Text("Includes \(itinerary.stopsLabel.lowercased()) — full connection details are shown on the booking site.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

private struct SegmentView: View {
    let segment: FlightSegment

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 4) {
                Text(DateUtil.time(segment.departure))
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                Image(systemName: "airplane")
                    .font(.caption2)
                    .foregroundStyle(Brand.coral)
                    .rotationEffect(.degrees(90))
                Text(DateUtil.time(segment.arrival))
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
            }
            .frame(width: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(segment.origin)
                    .font(.subheadline.weight(.semibold))
                Text("\(segment.carrierName ?? segment.carrierCode) · \(segment.carrierCode)\(segment.flightNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 2)
                Text(segment.destination)
                    .font(.subheadline.weight(.semibold))
            }
            Spacer()
        }
    }
}

private struct LayoverView: View {
    let from: Date
    let to: Date
    let airport: String

    private var minutes: Int { max(0, Int(to.timeIntervalSince(from) / 60)) }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "hourglass")
                .font(.caption2)
            Text("\(DateUtil.duration(minutes: minutes)) layover in \(airport)")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
        .padding(.leading, 70)
        .padding(.vertical, 2)
    }
}
