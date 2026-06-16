import Foundation
import Observation

/// Persists the traveller's onboarding preferences and the first-run completion
/// flag in `UserDefaults`. Mirrors the `DealStore` convention but is observable
/// so SwiftUI can react to onboarding completion.
@MainActor
@Observable
final class PreferencesStore {
    static let shared = PreferencesStore()

    private let defaults: UserDefaults

    private enum Key {
        static let preferences = "preferences.travel"
        static let completedOnboarding = "preferences.completedOnboarding"
    }

    var preferences: TravelPreferences {
        didSet { persistPreferences() }
    }

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.completedOnboarding) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Key.preferences),
           let decoded = try? JSONDecoder().decode(TravelPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = TravelPreferences()
        }
        self.hasCompletedOnboarding = defaults.bool(forKey: Key.completedOnboarding)
    }

    /// Saves the chosen preferences and marks onboarding as complete.
    func complete(with preferences: TravelPreferences) {
        self.preferences = preferences
        self.hasCompletedOnboarding = true
    }

    /// Clears saved preferences and the onboarding flag so the first-run flow
    /// is shown again (used by the "Log out" action).
    func logOut() {
        preferences = TravelPreferences()
        hasCompletedOnboarding = false
    }

    private func persistPreferences() {
        if let data = try? JSONEncoder().encode(preferences) {
            defaults.set(data, forKey: Key.preferences)
        }
    }
}
