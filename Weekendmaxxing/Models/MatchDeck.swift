import Foundation

/// The direction a card was swiped in the match deck.
enum SwipeDirection: String, Codable, Hashable {
    case pass        // left
    case match       // right
    case superMatch  // up
}

/// A single swipeable destination in the daily deck, plus the user's decision.
struct DeckCard: Codable, Identifiable, Hashable {
    var destination: Destination
    var swipe: SwipeDirection?

    var id: String { destination.id }
    var isSwiped: Bool { swipe != nil }
}

/// The persisted deck for a given day. A new deck is generated when `dayKey`
/// no longer matches today.
struct DeckState: Codable {
    var dayKey: String
    var cards: [DeckCard]
}
