import SwiftUI

struct SearchView: View {
    @State private var model: SearchViewModel
    @State private var loadTask: Task<Void, Never>?
    @State private var showingCityPicker = false

    private let service: TripService

    init(service: TripService) {
        self.service = service
        _model = State(initialValue: SearchViewModel(service: service))
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
            .navigationTitle("Search")
            .sheet(isPresented: $showingCityPicker) {
                CityPickerView(cities: model.cities, selection: $model.selectedCity)
            }
            .onChange(of: model.selectedCity?.code) { reload() }
            .onChange(of: model.origin) { reload() }
            .onChange(of: model.selectedWeekendIndex) { reload() }
            .onChange(of: model.weekendStyle) { reload() }
            .refreshable { await model.search() }
            .navigationDestination(for: TripOffer.self) { offer in
                OfferDetailView(
                    offer: offer,
                    weekend: model.selectedWeekend ?? WeekendCalculator.upcomingWeekends().first!
                )
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                showingCityPicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(Brand.coral)
                    if let city = model.selectedCity {
                        Text("\(city.flagEmoji) \(city.name)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    } else {
                        Text("Choose destination")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            Divider()

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
        }
        .padding(16)
        .cardStyle()
    }

    private var originMenu: some View {
        Menu {
            ForEach(Airport.londonOrigins) { airport in
                Button {
                    model.origin = airport
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
                ForEach(Array(model.weekends.enumerated()), id: \.element.id) { index, _ in
                    SelectableChip(
                        title: model.weekendTitle(index),
                        subtitle: nil,
                        isSelected: index == model.selectedWeekendIndex
                    ) {
                        model.selectedWeekendIndex = index
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
        case .idle:
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: "Where to?",
                message: "Pick a destination and a weekend to see live round-trip prices from London."
            )
        case .loading:
            LoadingView(message: "Searching flights…")
        case .empty:
            EmptyStateView(
                systemImage: "airplane",
                title: "No flights found",
                message: "Try a different weekend or another destination."
            )
        case .error(let message):
            ErrorStateView(message: message) { reload() }
        case .loaded(let offers):
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("^[\(offers.count) flight](inflect: true)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    sortMenu
                }

                if let source = offers.dataSource, source.isApproximate {
                    OfferSourceNote(source: source)
                }

                ForEach(offers) { offer in
                    NavigationLink(value: offer) {
                        OfferRow(offer: offer)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(OfferSort.allCases) { option in
                Button {
                    model.sort = option
                } label: {
                    if option == model.sort {
                        Label(option.title, systemImage: "checkmark")
                    } else {
                        Text(option.title)
                    }
                }
            }
        } label: {
            Label(model.sort.title, systemImage: "arrow.up.arrow.down")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.coral)
        }
    }

    private func reload() {
        guard model.canSearch else { return }
        loadTask?.cancel()
        loadTask = Task { await model.search() }
    }
}
