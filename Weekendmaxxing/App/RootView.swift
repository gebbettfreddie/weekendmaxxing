import SwiftUI

struct RootView: View {
    let tripService: TripService

    var body: some View {
        TabView {
            DiscoverView(service: tripService)
                .tabItem { Label("Discover", systemImage: "sparkles") }

            SearchView(service: tripService)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            SavedView(service: tripService)
                .tabItem { Label("Saved", systemImage: "bookmark.fill") }
        }
    }
}
