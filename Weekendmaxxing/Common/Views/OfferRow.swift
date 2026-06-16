import SwiftUI

/// A compact, tappable summary of a single round-trip offer.
struct OfferRow: View {
    let offer: TripOffer

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AirlineAvatar(code: offer.validatingAirline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(offer.airlineDisplay)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Text(offer.price.formattedRounded)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Brand.coral)
                }

                LegLine(label: "Out", itinerary: offer.outbound)
                if let inbound = offer.inbound {
                    LegLine(label: "Back", itinerary: inbound)
                }

                HStack(spacing: 6) {
                    InfoChip(systemImage: offer.isDirect ? "arrow.right" : "arrow.triangle.swap",
                             text: offer.isDirect ? "Direct" : "\(max(offer.outbound.stops, offer.inbound?.stops ?? 0)) stop")
                    InfoChip(systemImage: "clock", text: DateUtil.duration(minutes: offer.totalDurationMinutes))
                    if let seats = offer.seatsRemaining, seats <= 4 {
                        InfoChip(systemImage: "flame.fill", text: "\(seats) left")
                    }
                }
            }
        }
        .padding(14)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(offer.airlineDisplay), \(offer.price.formatted) return, \(offer.isDirect ? "direct" : "with a stop")")
    }
}

/// A small banner explaining where a result set's prices came from, so cached
/// or sample fares aren't mistaken for live, bookable quotes.
struct OfferSourceNote: View {
    let source: OfferSource

    private var tint: Color {
        switch source {
        case .live: return .green
        case .cached: return .orange
        case .sample: return .secondary
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: source.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(source.badgeText)
                    .font(.subheadline.weight(.semibold))
                Text(source.badgeDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(source.badgeText). \(source.badgeDetail)")
    }
}

/// A single direction's times and route, e.g. "Out  07:45 LGW → 11:10 BCN".
struct LegLine: View {
    let label: String
    let itinerary: Itinerary

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .leading)

            if let dep = itinerary.departure, let arr = itinerary.arrival {
                Text(DateUtil.time(dep))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Text(itinerary.origin ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Image(systemName: "airplane")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Text(DateUtil.time(arr))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Text(itinerary.destination ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

/// A small circular badge showing an airline's IATA code.
struct AirlineAvatar: View {
    let code: String

    var body: some View {
        Text(code)
            .font(.caption.weight(.heavy))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(Circle().fill(LinearGradient.forDestination(code)))
            .accessibilityHidden(true)
    }
}
