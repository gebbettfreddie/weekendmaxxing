import SwiftUI

/// App brand palette and shared visual tokens.
enum Brand {
    static let coral = Color(red: 0.984, green: 0.349, blue: 0.388)
    static let coralDeep = Color(red: 0.85, green: 0.20, blue: 0.30)
    static let ink = Color(red: 0.10, green: 0.11, blue: 0.15)

    /// Curated gradient pairs used as destination card backdrops.
    static let cardGradients: [[Color]] = [
        [Color(red: 0.99, green: 0.45, blue: 0.36), Color(red: 0.93, green: 0.23, blue: 0.51)],
        [Color(red: 0.31, green: 0.49, blue: 0.96), Color(red: 0.45, green: 0.78, blue: 0.96)],
        [Color(red: 0.18, green: 0.65, blue: 0.60), Color(red: 0.36, green: 0.85, blue: 0.62)],
        [Color(red: 0.55, green: 0.40, blue: 0.92), Color(red: 0.83, green: 0.45, blue: 0.95)],
        [Color(red: 0.98, green: 0.62, blue: 0.24), Color(red: 0.97, green: 0.40, blue: 0.32)],
        [Color(red: 0.16, green: 0.46, blue: 0.78), Color(red: 0.16, green: 0.72, blue: 0.78)],
        [Color(red: 0.93, green: 0.30, blue: 0.45), Color(red: 0.99, green: 0.55, blue: 0.39)],
        [Color(red: 0.20, green: 0.28, blue: 0.55), Color(red: 0.45, green: 0.40, blue: 0.85)]
    ]
}

extension LinearGradient {
    /// A deterministic, attractive gradient seeded by a destination code.
    static func forDestination(_ code: String) -> LinearGradient {
        let palettes = Brand.cardGradients
        let index = Int(SeededGenerator.stableHash(code) % UInt64(palettes.count))
        return LinearGradient(
            colors: palettes[index],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension View {
    /// Standard rounded card container styling.
    func cardStyle(cornerRadius: CGFloat = 20) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
