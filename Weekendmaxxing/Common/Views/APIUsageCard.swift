import SwiftUI

/// Shows how many live flight-data API requests the app has made this month and
/// in total, so the user can keep an eye on their (limited) free quotas.
struct APIUsageCard: View {
    @State private var usage = APIUsageTracker.shared
    @State private var showResetConfirm = false

    private let usingSampleData = AppConfig.usesMockData

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            counts

            if usingSampleData {
                Text("Using sample data — no live API requests are being made.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                providerBreakdown
            }

            if let last = usage.lastRequestDate {
                Text("Last request \(Self.relative.localizedString(for: last, relativeTo: Date()))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .cardStyle()
        .confirmationDialog(
            "Reset the request counter?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) { usage.reset() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack {
            Label("API usage", systemImage: "chart.bar.fill")
                .font(.subheadline.weight(.semibold))
            Spacer()
            if usage.totalAllTime > 0 {
                Button("Reset") { showResetConfirm = true }
                    .font(.caption.weight(.semibold))
                    .tint(Brand.coral)
            }
        }
    }

    private var counts: some View {
        HStack(spacing: 12) {
            stat(title: "This month", value: usage.totalThisMonth)
            Divider().frame(height: 38)
            stat(title: "All time", value: usage.totalAllTime)
        }
    }

    private var providerBreakdown: some View {
        VStack(spacing: 6) {
            ForEach(APIUsageTracker.Provider.allCases) { provider in
                HStack {
                    Text(provider.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(usage.thisMonth(for: provider)) this month · \(usage.allTime(for: provider)) total")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func stat(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.coral)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()
}
