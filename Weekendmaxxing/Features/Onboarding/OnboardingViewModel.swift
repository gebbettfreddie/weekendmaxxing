import Foundation
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    /// The ordered first-run steps.
    enum Step: Int, CaseIterable {
        case vibe
        case regions
        case weekendStyle
        case budget
        case accommodation
        case airportDistance
        case notifications

        var title: String {
            switch self {
            case .vibe: return "What are you after?"
            case .regions: return "Where do you fancy?"
            case .weekendStyle: return "How long a weekend?"
            case .budget: return "What's your budget?"
            case .accommodation: return "Where do you like to stay?"
            case .airportDistance: return "How far from the airport?"
            case .notifications: return "Catch price drops"
            }
        }

        var subtitle: String {
            switch self {
            case .vibe: return "We'll lean your suggestions this way."
            case .regions: return "Pick any regions, or none to see everywhere."
            case .weekendStyle: return "Pick the trip length that suits you."
            case .budget: return "Return flights from London per person."
            case .accommodation: return "Choose any that work for you."
            case .airportDistance: return "How far you'll travel once you land."
            case .notifications: return "Get a nudge when a weekend gets cheap."
            }
        }
    }

    /// Working copy of the preferences being assembled.
    var preferences = TravelPreferences()
    var step: Step = .vibe

    private let store: PreferencesStore
    private let onFinish: () -> Void

    init(store: PreferencesStore = .shared, onFinish: @escaping () -> Void) {
        self.store = store
        self.onFinish = onFinish
        self.preferences = store.preferences
    }

    var isFirstStep: Bool { step == Step.allCases.first }
    var isLastStep: Bool { step == Step.allCases.last }

    /// 0...1 progress used by the header bar.
    var progress: Double {
        let total = Double(Step.allCases.count)
        return Double(step.rawValue + 1) / total
    }

    var continueTitle: String { isLastStep ? "Start exploring" : "Continue" }

    /// The accommodation step requires at least one choice.
    var canContinue: Bool {
        switch step {
        case .accommodation: return !preferences.accommodationTypes.isEmpty
        default: return true
        }
    }

    func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    /// Advances to the next step, or finishes onboarding on the last step.
    func advance() {
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        } else {
            finish()
        }
    }

    func toggleAccommodation(_ type: AccommodationType) {
        if preferences.accommodationTypes.contains(type) {
            preferences.accommodationTypes.remove(type)
        } else {
            preferences.accommodationTypes.insert(type)
        }
    }

    func toggleRegion(_ region: Region) {
        if preferences.preferredRegions.contains(region) {
            preferences.preferredRegions.remove(region)
        } else {
            preferences.preferredRegions.insert(region)
        }
    }

    /// Opt in to notifications and request system permission immediately.
    func enableNotifications() async {
        let granted = await NotificationManager.shared.requestAuthorization()
        preferences.notificationsEnabled = granted
    }

    private func finish() {
        store.complete(with: preferences)
        // Once preferences are persisted, schedule background match alerts if
        // the traveller opted in to notifications.
        if preferences.notificationsEnabled {
            DealRefresh.schedule()
        }
        onFinish()
    }
}
