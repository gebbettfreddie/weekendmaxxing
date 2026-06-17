# AGENTS.md

Guidance for AI agents working in this repo. Keep changes minimal, match existing
style, and prefer editing existing files over adding new ones.

## What this project is

Two independent codebases in one repo:

1. **`Weekendmaxxing/`** — a native **SwiftUI iOS app** (iOS 17+, Swift 5, MVVM)
   that helps people in London find cheap weekend trips to Europe.
2. **`worker/`** — a **Cloudflare Worker** (TypeScript) proxy that fronts SerpApi,
   keeps the API key off the device, and caches queries in KV.

The app ships with bundled sample data and runs end-to-end with **no API keys**.

## Build / run

### iOS app
The `.xcodeproj` is **generated** from `project.yml` and is **gitignored**. Never
edit `project.pbxproj` by hand.

```bash
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig   # first time only
xcodegen generate                                            # after ANY add/remove/rename of source files or project.yml changes
```

Then build/run from Xcode, or headless:

```bash
xcodebuild -project Weekendmaxxing.xcodeproj -scheme Weekendmaxxing \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

> If you add, delete, or rename any file under `Weekendmaxxing/`, you MUST run
> `xcodegen generate` or the build won't see it.

### Worker
```bash
cd worker
npm install
npm run dev      # http://localhost:8787 with local KV
npm run deploy   # deploy to Cloudflare
```

## Architecture (iOS)

```
Weekendmaxxing/
  App/          Entry point, root tab navigation, theme
  Models/       Destination, TripOffer, Price, Airport, WeekendWindow, City, Deal
  Services/     TripService protocol + implementations, AppConfig, stores
  Features/     Discover, Search, Saved, Detail, Alerts, Onboarding (View + ViewModel each)
  Common/       WeekendCalculator, formatters, reusable views
  Persistence/  SwiftData model + saved-trips store
  Resources/    Sample JSON, asset catalog, Info.plist
```

- **Data layer is protocol-based.** Everything goes through `TripService`
  (`Services/TripService.swift`). Implementations: `MockTripService`,
  `TravelpayoutsTripService`, `SerpApiTripService`, plus the composing
  `FallbackTripService` and `HybridTripService`.
- **`AppConfig.makeTripService()`** is the single place that wires which service
  is used, based on `Config/Secrets.xcconfig` values surfaced via Info.plist.
- **Each feature is a `View` + `ViewModel` pair** and is otherwise self-contained.
- New work should conform to `TripService` rather than calling APIs from views.

## Conventions

- SwiftUI + MVVM. ViewModels own state; views stay declarative.
- Keep services `Sendable` and use `async`/`await` (see existing `withTaskGroup`
  batching in `TripService`).
- Don't add narrating comments; comment only non-obvious intent.

## Hard rules

- **Never commit `Config/Secrets.xcconfig`** (gitignored) or `worker/.dev.vars`.
  Tokens live there only. Never paste real tokens into code or chat.
- **Never edit or commit** anything under `build/`, `.build/`, or the generated
  `*.xcodeproj` — all gitignored.
- The real shared config file is **`project.yml`**, not the `.xcodeproj`. Treat
  edits to it (deps, build settings) as a single-owner change.

## Working in parallel (multiple agents)

Clean seams where agents can work simultaneously with minimal conflict:

| Seam | Agent A | Agent B |
| --- | --- | --- |
| Backend vs client | `worker/src/index.ts` | Swift app consuming the proxy |
| Service vs feature | a new/changed `TripService` impl | the feature/UI that uses it |
| Feature vs feature | `Features/Discover/*` | `Features/Search/*` (etc.) |
| Code vs assets | Swift logic | `Resources/*.json`, assets, `docs/` |

Tips:
- **Agree on the contract first** when two agents share a boundary (the
  `TripService` protocol, a DTO in `TravelpayoutsDTOs.swift`, or the Worker's JSON
  shape), then each side can build/mock against it independently.
- **Use a separate git worktree per editing agent.** Because the `.xcodeproj` is
  regenerated per checkout, two worktrees can each `xcodegen generate` without
  colliding on `project.pbxproj`.
- **Builds are a serialized bottleneck.** Give each worktree its own DerivedData
  (`-derivedDataPath`) or stagger `xcodebuild` runs instead of running them at once.
- Keep `project.yml` edits owned by one agent to avoid merge conflicts.
