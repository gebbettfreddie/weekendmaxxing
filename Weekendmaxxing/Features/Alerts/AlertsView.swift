import SwiftUI
import UIKit

/// The hero "Alerts" tab: turn on cheap-deal notifications, set a budget, and
/// browse the deals found so far.
struct AlertsView: View {
    @State private var model: AlertsViewModel
    @State private var path: [Destination] = []
    @State private var checkTask: Task<Void, Never>?

    @Environment(AppRouter.self) private var router
    @Environment(\.openURL) private var openURL

    private let service: TripService

    init(service: TripService) {
        self.service = service
        _model = State(initialValue: AlertsViewModel(service: service))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 20) {
                    hero
                    settingsCard
                    checkButton
                    recentSection
                }
                .padding(.horizontal)
                .padding(.bottom, 28)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Deal alerts")
            .navigationDestination(for: Destination.self) { destination in
                TripDetailView(service: service, originCode: "LON", destination: destination)
            }
        }
        .task { await model.onAppear() }
        .onChange(of: router.pendingDealDestination) { _, destination in
            guard let destination else { return }
            path = [destination]
            router.pendingDealDestination = nil
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 30))
                .foregroundStyle(Brand.coral)
            Text("Never miss a steal")
                .font(.title2.weight(.heavy))
            Text("We'll watch flights from London and ping you the moment something turns up far below its usual price.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .cardStyle()
    }

    // MARK: - Settings

    private var settingsCard: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: $model.enabled) {
                Text("Alert me to cheap deals")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(Brand.coral)

            if model.permissionDenied {
                permissionBanner
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Only deals under")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(model.budgetLabel)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Brand.coral)
                }
                Slider(
                    value: $model.maxBudget,
                    in: DealRules.minBudget...DealRules.maxBudget,
                    step: 10
                )
                .tint(Brand.coral)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var permissionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Notifications are off")
                    .font(.caption.weight(.semibold))
                Text("Turn them on in Settings to get alerts.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            .font(.caption.weight(.semibold))
            .tint(Brand.coral)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.orange.opacity(0.12)))
    }

    // MARK: - Check now

    private var checkButton: some View {
        Button {
            checkTask?.cancel()
            checkTask = Task { await model.checkNow() }
        } label: {
            HStack {
                if model.isChecking {
                    ProgressView().controlSize(.small)
                    Text("Checking…")
                } else {
                    Image(systemName: "arrow.clockwise")
                    Text("Check for deals now")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Brand.coral)
        .controlSize(.large)
        .disabled(model.isChecking)
    }

    // MARK: - Recent deals

    @ViewBuilder
    private var recentSection: some View {
        if model.recentDeals.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "binoculars")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("No deals just yet")
                    .font(.headline)
                Text("We'll keep watching. When a fare drops well below its usual price, it'll appear here and you'll get a notification.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .padding(.horizontal, 12)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                Text("Recent deals")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(model.recentDeals) { deal in
                    NavigationLink(value: deal.destination) {
                        DealCard(deal: deal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// A recent-deal card: photo, savings badge, current vs usual price.
private struct DealCard: View {
    let deal: Deal

    private var city: City { deal.destination.city }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DestinationBanner(city: city, height: 128)
            .overlay(alignment: .topLeading) {
                Text("\(deal.savingsPercent)% off")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Brand.coral))
                    .padding(10)
            }
            .overlay(alignment: .topTrailing) {
                PriceTag(price: deal.price, prefix: "now")
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(deal.cityName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Label {
                    Text(DateUtil.weekendLabel(deal.weekend))
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Text("Usually \(deal.baselinePrice.formattedRounded)")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .strikethrough()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(deal.cityName), \(deal.price.formattedRounded), \(deal.savingsPercent) percent off, \(DateUtil.weekendLabel(deal.weekend))")
    }
}
