import SwiftUI

struct RootView: View {
    let tripService: TripService
    @State private var router = AppRouter()

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            DiscoverView(service: tripService)
                .tabItem { Label("Discover", systemImage: "sparkles") }
                .tag(AppRouter.Tab.discover)

            SearchView(service: tripService)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(AppRouter.Tab.search)

            AlertsView(service: tripService)
                .tabItem { Label("Alerts", systemImage: "bell.fill") }
                .tag(AppRouter.Tab.alerts)

            SavedView(service: tripService)
                .tabItem { Label("Saved", systemImage: "bookmark.fill") }
                .tag(AppRouter.Tab.saved)
        }
        .environment(router)
        .onAppear {
            NotificationManager.shared.onOpenDeal = { id in
                router.openDeal(id: id)
            }
        }
    }
}
