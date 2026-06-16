import SwiftUI

/// A tappable card summarising a discovered weekend destination.
struct DestinationCard: View {
    let destination: Destination

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DestinationBanner(
                code: destination.city.code,
                flagEmoji: destination.flagEmoji,
                imageURL: destination.city.photoURL,
                height: 132
            )
            .overlay(alignment: .topTrailing) {
                PriceTag(price: destination.price, prefix: "from")
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(destination.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Label {
                    Text(DateUtil.weekendLabel(destination.weekend))
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Text(destination.country)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(destination.name), \(destination.country). From \(destination.price.formattedRounded), \(DateUtil.weekendLabel(destination.weekend))"
        )
    }
}
