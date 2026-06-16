import SwiftUI

struct DiscoverView: View {
    @State private var model: DiscoverViewModel
    @State private var loadTask: Task<Void, Never>?
    @State private var showLogOutConfirm = false

    private let service: TripService

    init(service: TripService) {
        self.service = service
        _model = State(initialValue: DiscoverViewModel(service: service))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    controls
                    results
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Weekend escapes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showLogOutConfirm = true
                    } label: {
                        Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Label(model.dataSourceLabel, systemImage: model.usingSampleData ? "shippingbox" : "dot.radiowaves.up.forward")
                        .labelStyle(.titleAndIcon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .confirmationDialog("Log out?", isPresented: $showLogOutConfirm, titleVisibility: .visible) {
                Button("Log out", role: .destructive) {
                    PreferencesStore.shared.logOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your saved preferences and restarts the welcome flow.")
            }
            .refreshable { await model.load() }
            .task {
                if case .idle = model.state { await model.load() }
            }
            .navigationDestination(for: Destination.self) { destination in
                TripDetailView(
                    service: service,
                    originCode: model.origin.code,
                    destination: destination
                )
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("From", systemImage: "airplane.departure")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                originMenu
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("When")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    stylePicker
                }
                weekendChips
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Budget")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(model.budgetLabel)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Brand.coral)
                }
                Slider(value: $model.maxBudget, in: 50...500, step: 10) { editing in
                    if !editing { reload() }
                }
                .tint(Brand.coral)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var originMenu: some View {
        Menu {
            ForEach(Airport.londonOrigins) { airport in
                Button {
                    model.origin = airport
                    reload()
                } label: {
                    if airport == model.origin {
                        Label(airport.name, systemImage: "checkmark")
                    } else {
                        Text(airport.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(model.origin.name)
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(.primary)
        }
    }

    private var stylePicker: some View {
        Menu {
            ForEach(WeekendStyle.allCases) { style in
                Button {
                    model.weekendStyle = style
                    reload()
                } label: {
                    if style == model.weekendStyle {
                        Label(style.title, systemImage: "checkmark")
                    } else {
                        Text(style.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(model.weekendStyle.title)
                    .font(.caption.weight(.semibold))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
    }

    private var weekendChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectableChip(
                    title: model.bestPriceTitle,
                    subtitle: model.bestPriceSubtitle,
                    isSelected: model.isBestPriceSelected
                ) {
                    model.selectBestPrice()
                    reload()
                }

                ForEach(Array(model.weekends.enumerated()), id: \.element.id) { index, _ in
                    SelectableChip(
                        title: model.weekendTitle(index),
                        subtitle: model.weekendSubtitle(index),
                        isSelected: model.selection == .weekend(index)
                    ) {
                        model.selectWeekend(index)
                        reload()
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var results: some View {
        switch model.state {
        case .idle, .loading:
            LoadingView(message: model.loadingMessage)
        case .empty:
            EmptyStateView(
                title: "No trips in budget",
                message: "Try a higher budget or a different weekend to see more destinations."
            )
        case .error(let message):
            ErrorStateView(message: message) { reload() }
        case .loaded(let destinations):
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("^[\(destinations.count) destination](inflect: true) from London")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if model.isBestPriceSelected {
                        Text("Cheapest weekend for each city over the next \(model.bestPriceMonths) months")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Label("Indicative \u{201C}from\u{201D} fares \u{00B7} live prices shown when you open a trip", systemImage: "info.circle")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(destinations) { destination in
                    NavigationLink(value: destination) {
                        DestinationCard(destination: destination)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func reload() {
        loadTask?.cancel()
        loadTask = Task { await model.load() }
    }
}
