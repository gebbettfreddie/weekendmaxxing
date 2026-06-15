import SwiftUI
import SwiftData

@main
struct WeekendmaxxingApp: App {
    private let tripService = AppConfig.makeTripService()

    var body: some Scene {
        WindowGroup {
            RootView(tripService: tripService)
                .fontDesign(.rounded)
                .tint(Brand.coral)
        }
        .modelContainer(for: SavedTrip.self)
    }
}
