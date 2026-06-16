import SwiftUI

struct OnboardingView: View {
    @State private var model: OnboardingViewModel

    init(store: PreferencesStore = .shared, onFinish: @escaping () -> Void) {
        _model = State(initialValue: OnboardingViewModel(store: store, onFinish: onFinish))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.step.title)
                            .font(.title.bold())
                        Text(model.step.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    stepContent
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            footer
        }
        .background(Color(.systemGroupedBackground))
        .animation(.easeInOut(duration: 0.25), value: model.step)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(OnboardingViewModel.Step.allCases, id: \.rawValue) { step in
                    Capsule()
                        .fill(step.rawValue <= model.step.rawValue ? AnyShapeStyle(Brand.coral) : AnyShapeStyle(Color(.tertiarySystemFill)))
                        .frame(height: 5)
                }
            }
            HStack {
                Text("Step \(model.step.rawValue + 1) of \(OnboardingViewModel.Step.allCases.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        switch model.step {
        case .vibe: vibeStep
        case .weekendStyle: weekendStyleStep
        case .budget: budgetStep
        case .accommodation: accommodationStep
        case .airportDistance: airportDistanceStep
        case .notifications: notificationsStep
        }
    }

    private var vibeStep: some View {
        VStack(spacing: 12) {
            ForEach(TripVibe.allCases) { vibe in
                OptionRow(
                    title: vibe.title,
                    systemImage: vibe.systemImage,
                    isSelected: model.preferences.tripVibe == vibe
                ) {
                    model.preferences.tripVibe = vibe
                }
            }
        }
    }

    private var weekendStyleStep: some View {
        VStack(spacing: 12) {
            ForEach(WeekendStyle.allCases) { style in
                OptionRow(
                    title: style.title,
                    subtitle: style == .fridayToSunday ? "2 nights away" : "1 night away",
                    systemImage: "calendar",
                    isSelected: model.preferences.weekendStyle == style
                ) {
                    model.preferences.weekendStyle = style
                }
            }
        }
    }

    private var budgetStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(budgetLabel)
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.coral)
                .frame(maxWidth: .infinity, alignment: .center)

            Slider(value: $model.preferences.maxBudget, in: 50...500, step: 10)
                .tint(Brand.coral)

            HStack {
                Text("£50")
                Spacer()
                Text("Any")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .cardStyle()
    }

    private var accommodationStep: some View {
        VStack(spacing: 12) {
            ForEach(AccommodationType.allCases) { type in
                OptionRow(
                    title: type.title,
                    systemImage: type.systemImage,
                    isSelected: model.preferences.accommodationTypes.contains(type),
                    showsCheckmark: true
                ) {
                    model.toggleAccommodation(type)
                }
            }
        }
    }

    private var airportDistanceStep: some View {
        VStack(spacing: 12) {
            ForEach(AirportDistance.allCases) { distance in
                OptionRow(
                    title: distance.title,
                    systemImage: distance.systemImage,
                    isSelected: model.preferences.airportDistance == distance
                ) {
                    model.preferences.airportDistance = distance
                }
            }
        }
    }

    private var notificationsStep: some View {
        VStack(spacing: 16) {
            Image(systemName: model.preferences.notificationsEnabled ? "bell.badge.fill" : "bell.fill")
                .font(.system(size: 52))
                .foregroundStyle(Brand.coral)
                .padding(.top, 8)

            Text("We'll watch fares and ping you when a weekend escape drops below its usual price.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if model.preferences.notificationsEnabled {
                Label("Notifications on", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.coral)
            } else {
                Button {
                    Task { await model.enableNotifications() }
                } label: {
                    Text("Enable notifications")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Brand.coral, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .cardStyle()
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            if !model.isFirstStep {
                Button(action: model.back) {
                    Text("Back")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }

            Button(action: model.advance) {
                Text(model.continueTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(model.canContinue ? Brand.coral : Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(model.canContinue ? Color.white : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(!model.canContinue)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
    }

    // MARK: - Helpers

    private var budgetLabel: String {
        model.preferences.maxBudget >= 500
            ? "Any budget"
            : "Under \(CurrencyFormatter.string(amount: model.preferences.maxBudget, currency: "GBP", fractionDigits: 0))"
    }
}

/// A tappable full-width selectable row used across the onboarding steps.
private struct OptionRow: View {
    let title: String
    var subtitle: String?
    let systemImage: String
    let isSelected: Bool
    var showsCheckmark: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .frame(width: 28)
                    .foregroundStyle(isSelected ? Color.white : Brand.coral)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .opacity(0.85)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: showsCheckmark ? "checkmark.circle.fill" : "checkmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Brand.coral) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView {}
}
