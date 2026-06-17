import SwiftUI
import SwiftData

/// The Tinder/Hinge-style home: a daily deck of preference-matched destinations
/// the traveller swipes through. Right = match, left = pass, up = super-match.
struct MatchView: View {
    @State private var model: MatchViewModel
    @State private var topOffset: CGSize = .zero
    @State private var route: Destination?
    @State private var loadTask: Task<Void, Never>?
    @State private var showLogOutConfirm = false

    @Environment(\.modelContext) private var modelContext

    private let service: TripService

    private let swipeThreshold: CGFloat = 110
    private let superThreshold: CGFloat = 150

    init(service: TripService) {
        self.service = service
        _model = State(initialValue: MatchViewModel(service: service))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                content
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $route) { destination in
                TripDetailView(service: service, originCode: "LON", destination: destination)
            }
            .confirmationDialog("Log out?", isPresented: $showLogOutConfirm, titleVisibility: .visible) {
                Button("Log out", role: .destructive) {
                    PreferencesStore.shared.logOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your saved preferences and restarts the welcome flow.")
            }
            .task {
                if case .idle = model.state { await model.load() }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's matches")
                    .font(.largeTitle.weight(.bold))
                Text(headerSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button(role: .destructive) {
                    showLogOutConfirm = true
                } label: {
                    Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 32))
                    .foregroundStyle(Brand.coral)
            }
            .accessibilityLabel("Profile")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var headerSubtitle: String {
        switch model.state {
        case .loaded where !model.cards.isEmpty:
            return "^[\(model.picksRemaining) pick](inflect: true) left today"
        default:
            return "Swipe right to match, left to pass"
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            Spacer(minLength: 0)
            LoadingView(message: model.loadingMessage)
            Spacer(minLength: 0)
        case .error(let message):
            Spacer(minLength: 0)
            ErrorStateView(message: message) { reload() }
            Spacer(minLength: 0)
        case .loaded:
            if model.noPicks {
                emptyState(
                    icon: "slider.horizontal.3",
                    title: "No picks today",
                    message: "Nothing matched your filters. Widen your budget or regions in your profile to see more."
                )
            } else if model.allSwiped {
                emptyState(
                    icon: "checkmark.circle.fill",
                    title: "You're all caught up",
                    message: "That's today's three. New matches land tomorrow — we'll keep watching for anything that fits in the meantime."
                )
            } else {
                deck
                actionButtons
            }
        }
    }

    // MARK: - Deck

    private var deck: some View {
        GeometryReader { geo in
            let cardSize = CGSize(width: geo.size.width - 40, height: geo.size.height - 12)
            ZStack {
                ForEach(Array(model.pendingCards.prefix(3).enumerated()), id: \.element.id) { index, card in
                    let isTop = index == 0
                    DeckCardView(destination: card.destination, height: cardSize.height)
                        .frame(width: cardSize.width, height: cardSize.height)
                        .scaleEffect(isTop ? 1 : 1 - CGFloat(index) * 0.04)
                        .offset(y: isTop ? topOffset.height : CGFloat(index) * 12)
                        .offset(x: isTop ? topOffset.width : 0)
                        .rotationEffect(.degrees(isTop ? Double(topOffset.width / 18) : 0))
                        .overlay { if isTop { swipeLabels } }
                        .zIndex(isTop ? 100 : Double(3 - index))
                        .allowsHitTesting(isTop)
                        .gesture(isTop ? dragGesture : nil)
                        .onTapGesture { if isTop { route = card.destination } }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private var swipeLabels: some View {
        ZStack {
            stampLabel("MATCH", color: .green)
                .opacity(Double(max(0, topOffset.width) / swipeThreshold))
                .rotationEffect(.degrees(-14))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            stampLabel("PASS", color: .red)
                .opacity(Double(max(0, -topOffset.width) / swipeThreshold))
                .rotationEffect(.degrees(14))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            stampLabel("SUPER", color: .blue)
                .opacity(Double(max(0, -topOffset.height) / superThreshold))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 40)
        }
        .padding(24)
    }

    private func stampLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 34, weight: .heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(color, lineWidth: 4)
            )
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        HStack(spacing: 28) {
            circleButton(icon: "xmark", tint: .red) { commitSwipe(.pass) }
            circleButton(icon: "star.fill", tint: .blue, size: 52) { commitSwipe(.superMatch) }
            circleButton(icon: "heart.fill", tint: Brand.coral) { commitSwipe(.match) }
        }
        .padding(.top, 14)
        .padding(.bottom, 18)
    }

    private func circleButton(icon: String, tint: Color, size: CGFloat = 62, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty / states

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack {
            Spacer(minLength: 0)
            VStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 46))
                    .foregroundStyle(Brand.coral)
                Text(title)
                    .font(.title3.weight(.bold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 36)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Swipe handling

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                topOffset = value.translation
            }
            .onEnded { value in
                let t = value.translation
                if t.height < -superThreshold && abs(t.width) < swipeThreshold {
                    commitSwipe(.superMatch)
                } else if t.width > swipeThreshold {
                    commitSwipe(.match)
                } else if t.width < -swipeThreshold {
                    commitSwipe(.pass)
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { topOffset = .zero }
                }
            }
    }

    private func commitSwipe(_ direction: SwipeDirection) {
        guard model.topCard != nil else { return }
        withAnimation(.easeIn(duration: 0.28)) { topOffset = flyTarget(direction) }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 290_000_000)
            if let card = model.swipe(direction), direction != .pass {
                SavedTripsStore.save(SavedTrip(destination: card.destination), context: modelContext)
            }
            topOffset = .zero
        }
    }

    private func flyTarget(_ direction: SwipeDirection) -> CGSize {
        switch direction {
        case .pass: return CGSize(width: -700, height: 60)
        case .match: return CGSize(width: 700, height: 60)
        case .superMatch: return CGSize(width: 0, height: -900)
        }
    }

    private func reload() {
        loadTask?.cancel()
        loadTask = Task { await model.refresh() }
    }
}

/// A single full-bleed destination card for the swipe deck.
private struct DeckCardView: View {
    let destination: Destination
    var height: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            DestinationBanner(city: destination.city, height: height)

            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    ForEach(Array(destination.city.resolvedVibes).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { vibe in
                        tagChip(vibe == .beach ? "Beach" : "City", systemImage: vibe == .beach ? "beach.umbrella.fill" : "building.2.fill")
                    }
                    tagChip(destination.city.resolvedRegion.title, systemImage: destination.city.resolvedRegion.systemImage)
                }

                Text(destination.name)
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)

                Label(DateUtil.weekendLabel(destination.weekend), systemImage: "calendar")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.92))

                Text(destination.country)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(20)
        }
        .overlay(alignment: .topTrailing) {
            PriceTag(price: destination.price, prefix: "from")
                .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(destination.name), \(destination.country), from \(destination.price.formattedRounded), \(DateUtil.weekendLabel(destination.weekend))")
    }

    private func tagChip(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption2)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(.ultraThinMaterial))
        .environment(\.colorScheme, .dark)
    }
}
