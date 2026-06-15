import Foundation
import SwiftData

/// Thin helper around `ModelContext` for saving/removing trips with dedupe.
@MainActor
enum SavedTripsStore {
    static func isSaved(id: String, context: ModelContext) -> Bool {
        var descriptor = FetchDescriptor<SavedTrip>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    @discardableResult
    static func save(_ trip: SavedTrip, context: ModelContext) -> Bool {
        guard !isSaved(id: trip.id, context: context) else { return false }
        context.insert(trip)
        try? context.save()
        return true
    }

    static func remove(id: String, context: ModelContext) {
        let descriptor = FetchDescriptor<SavedTrip>(predicate: #Predicate { $0.id == id })
        guard let matches = try? context.fetch(descriptor) else { return }
        for match in matches { context.delete(match) }
        try? context.save()
    }

    /// Saves if not present, otherwise removes. Returns the new saved state.
    @discardableResult
    static func toggle(_ trip: SavedTrip, context: ModelContext) -> Bool {
        if isSaved(id: trip.id, context: context) {
            remove(id: trip.id, context: context)
            return false
        } else {
            context.insert(trip)
            try? context.save()
            return true
        }
    }
}
