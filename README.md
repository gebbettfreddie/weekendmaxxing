# Weekendmaxxing

A native SwiftUI iOS app that helps people in London find low-cost weekend trips to Europe.

- **Discover** the cheapest places you can fly from London this weekend, within your budget.
- **Search** a specific destination and dates for concrete priced flight offers.
- **Save** trips you like for later (stored locally with SwiftData).

The app ships with realistic bundled sample data, so it runs end-to-end in the simulator with **no API keys required**. Add a Travelpayouts token to switch to live data.

## Requirements

- macOS with **Xcode 16+** (only Apple Command Line Tools are needed to generate the project; the full Xcode app is required to build and run).
- [XcodeGen](https://github.com/yonyz/XcodeGen) to generate the `.xcodeproj` from `project.yml`:

```bash
brew install xcodegen
```

## Getting started

```bash
# 1. Create your local build config (gitignored)
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig

# 2. Generate the Xcode project
xcodegen generate

# 3. Open and run
open Weekendmaxxing.xcodeproj
```

Then pick an iPhone simulator and hit Run. With the default config (`USE_MOCK = YES`) you'll see sample destinations and offers immediately.

## Using live flight data (optional)

> **Why Travelpayouts?** Amadeus is decommissioning its Self-Service API portal on **July 17, 2026** (all self-service keys are disabled that day). The app has migrated to the free [Travelpayouts](https://www.travelpayouts.com) (Aviasales) Flight Data API, which also lets you earn affiliate commission on booking hand-offs.

1. Create a free account at [travelpayouts.com](https://www.travelpayouts.com), then grab your **API token** (Developers → Data API) and, optionally, your **affiliate marker**.
2. Edit `Config/Secrets.xcconfig`:

```
TRAVELPAYOUTS_TOKEN = your_token
TRAVELPAYOUTS_MARKER = your_marker   # optional, used for commissionable booking links
USE_MOCK = NO
```

3. Re-run `xcodegen generate` (only needed if you change `project.yml`) and rebuild.

The app calls one Travelpayouts endpoint for both jobs:

- Discovery: `GET /aviasales/v3/prices_for_dates` *without* a destination (cheapest fare to every reachable city for the weekend).
- Search: `GET /aviasales/v3/prices_for_dates` *with* a destination (priced fares for a route + dates).

> Note: prices are **indicative** (cached from real searches) rather than live bookable quotes, and the free tier is rate-limited per minute/month. If a live call returns no results or hits the quota, the app gracefully falls back to bundled sample data.

## Architecture

SwiftUI + MVVM. A `TripService` protocol abstracts the data layer with two implementations: `MockTripService` (bundled JSON) and `TravelpayoutsTripService` (live API), selected at launch by `AppConfig`.

```
Weekendmaxxing/
  App/          App entry + root tab navigation + theme
  Models/       Destination, TripOffer, Price, Airport, WeekendWindow
  Services/     TripService protocol, Mock + Travelpayouts implementations, AppConfig
  Features/     Discover, Search, Saved, Detail (View + ViewModel each)
  Common/       WeekendCalculator, formatters, reusable views
  Persistence/  SwiftData model + saved-trips store
  Resources/    Sample data, asset catalog, Info.plist
```

## Security note

For a real release, move the Travelpayouts token behind a small server-side proxy and have the app call that instead of embedding the token. The current setup (gitignored `xcconfig`) is fine for development and prototyping only.
