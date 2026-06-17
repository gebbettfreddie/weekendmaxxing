import SwiftUI

struct RootView: View {
    let tripService: TripService
    @State private var router = AppRouter()
    @State private var preferences = PreferencesStore.shared

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            MatchView(service: tripService)
                .tabItem { Label("Match", systemImage: "flame.fill") }
                .tag(AppRouter.Tab.match)

            SearchView(service: tripService)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(AppRouter.Tab.search)

            AlertsView(service: tripService)
                .tabItem { Label("Alerts", systemImage: "bell.fill") }
                .tag(AppRouter.Tab.alerts)

            SavedView(service: tripService)
                .tabItem { Label("Matches", systemImage: "heart.fill") }
                .tag(AppRouter.Tab.saved)
        }
        .environment(router)
        .onAppear {
            NotificationManager.shared.onOpenDeal = { id in
                router.openDeal(id: id)
            }
            NotificationManager.shared.onOpenMatch = { cityCode in
                router.openMatch(cityCode: cityCode)
            }
        }
        .fullScreenCover(isPresented: .constant(!preferences.hasCompletedOnboarding)) {
            OnboardingView(store: preferences) {}
                .interactiveDismissDisabled()
        }
    }
}
