import SwiftUI
import SwiftData

@main
struct WeekendmaxxingApp: App {
    private let tripService = AppConfig.makeTripService()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        NotificationManager.shared.registerAsDelegate()
        DealRefresh.register(service: tripService)
    }

    var body: some Scene {
        WindowGroup {
            RootView(tripService: tripService)
                .fontDesign(.rounded)
                .tint(Brand.coral)
        }
        .modelContainer(for: SavedTrip.self)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { DealRefresh.schedule() }
        }
    }
}
