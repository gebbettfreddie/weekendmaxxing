import SwiftUI

/// A colourful destination header: a deterministic gradient (seeded by the city
/// code) with a large translucent flag, and a photo on top. Catalog cities use
/// their bundled image; any other city's photo is resolved at runtime from
/// Wikipedia via `CityImageResolver` (cached).
struct DestinationBanner: View {
    let city: City
    var height: CGFloat = 140

    @State private var resolvedURL: URL?

    private var imageURL: URL? { city.imageURL ?? resolvedURL }

    var body: some View {
        // The flexible gradient drives the layout size; the flag, photo, and scrim
        // are non-sizing overlays (clipped to the gradient). Layering them inside a
        // ZStack instead lets the large flag emoji's intrinsic width expand the
        // banner past its proposed width, which breaks callers that size to it.
        LinearGradient.forDestination(city.code)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay {
                Text(city.flagEmoji)
                    .font(.system(size: height * 0.62))
                    .opacity(0.30)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            }
            .overlay {
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
            }
            .overlay {
                LinearGradient(
                    colors: [.black.opacity(0.0), .black.opacity(0.22)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .clipped()
            .task(id: city.code) {
            guard city.imageURL == nil, resolvedURL == nil else { return }
            resolvedURL = await CityImageResolver.shared.imageURL(for: city)
        }
    }
}
