import Foundation

extension Array {
    /// Safe indexed access that returns nil instead of trapping out of bounds.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
