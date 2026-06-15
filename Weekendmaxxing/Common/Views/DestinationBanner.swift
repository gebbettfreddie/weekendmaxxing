import SwiftUI

/// A colourful destination header: a deterministic gradient (seeded by the city
/// code) with a large translucent flag, and an optional remote photo on top.
struct DestinationBanner: View {
    let code: String
    let flagEmoji: String
    var imageURL: URL?
    var height: CGFloat = 140

    var body: some View {
        ZStack {
            LinearGradient.forDestination(code)

            Text(flagEmoji)
                .font(.system(size: height * 0.62))
                .opacity(0.30)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .transition(.opacity)
                    } else {
                        Color.clear
                    }
                }
            }

            LinearGradient(
                colors: [.black.opacity(0.0), .black.opacity(0.22)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}
