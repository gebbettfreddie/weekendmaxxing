import Foundation

/// Launch-argument hooks used by the UX-audit screenshot harness
/// (`tools/ux-audit/`) to drive the app into specific states without manual
/// interaction. DEBUG-only: in release builds every hook is inert, so none of
/// this affects shipping behaviour.
///
/// Tab selection and onboarding completion are driven separately: `initialTab`
/// is read from `UserDefaults` by `AppRouter`, and onboarding is forced by
/// clearing the `preferences.completedOnboarding` default before launch.
enum UITestHooks {
    #if DEBUG
    private static var args: [String] { ProcessInfo.processInfo.arguments }

    /// Present the "It's a match!" celebration over the deck on launch.
    static var celebrateOnLaunch: Bool { args.contains("-uiCelebrate") }

    /// Push the top deck card's trip detail screen on launch.
    static var routeTopCardOnLaunch: Bool { args.contains("-uiRouteTopCard") }

    /// Start the onboarding flow at a specific (0-based) step index.
    static var onboardingStartStep: Int? {
        guard let i = args.firstIndex(of: "-uiOnboardingStep"), i + 1 < args.count else { return nil }
        return Int(args[i + 1])
    }
    #else
    static var celebrateOnLaunch: Bool { false }
    static var routeTopCardOnLaunch: Bool { false }
    static var onboardingStartStep: Int? { nil }
    #endif
}
