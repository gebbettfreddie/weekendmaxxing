---
name: ux-audit
description: Walk the Weekendmaxxing app through every flow in the iOS Simulator, screenshot each stage, benchmark against Tinder/Hinge/Skyscanner, and produce a visual report + prioritized improvement backlog. Use when the user wants a UX/UI audit, competitor comparison, or "how can we improve the app" review.
---

# UX audit agent

Produces a screen-by-screen UX review of Weekendmaxxing benchmarked against
Tinder, Hinge, and Skyscanner. Output: a self-contained HTML report (published
as an artifact) plus a prioritized backlog.

Everything lives under `tools/ux-audit/`:
- `capture-app.sh` — drives the app and screenshots each scene → `shots/app/`
- `build-report.py` — embeds the screenshots + critique into `report.html`
- `competitors.md` — researched competitor UX patterns (reference)
- `backlog.md` — the prioritized improvement list

## How the app is driven (no taps needed)

Real device automation (idb/XCUITest) isn't set up, so scenes are reached via
launch state instead of synthetic taps:
- Tab selection: `-initialTab match|search|alerts|saved` (read by `AppRouter`).
- Onboarding: clear/set `preferences.completedOnboarding` via `simctl … defaults`.
- Interactive states via the **DEBUG-only** `UITestHooks` (`Weekendmaxxing/App/UITestHooks.swift`):
  `-uiCelebrate` (match celebration), `-uiRouteTopCard` (trip detail),
  `-uiOnboardingStep N` (start onboarding at step N). These are inert in release builds.

If you add a new screen worth auditing, add a `shoot …` line to `capture-app.sh`
(and a hook to `UITestHooks` if it needs a non-default state), then add its
critique entry to the `SCREENS` list in `build-report.py`.

## Run it

```bash
# 1. Capture screens (builds the app, boots the sim, screenshots each scene)
tools/ux-audit/capture-app.sh --sim "iPhone 17"      # use an installed sim name

# 2. (Optional) refresh competitor research — research Tinder/Hinge/Skyscanner
#    flow patterns from PUBLIC sources only (teardowns, reviews, product blogs).
#    Do not attempt to drive the live apps. Save findings to competitors.md.

# 3. Build the report and publish it
python3 tools/ux-audit/build-report.py            # writes report.html
```

Then publish `tools/ux-audit/report.html` with the Artifact tool, and surface the
P0 items from `backlog.md` to the user.

## Notes / gotchas

- `iPhone 16` is often not installed; list with `xcrun simctl list devices` and
  pass an available one via `--sim`.
- The critique in `build-report.py` is authored, not auto-generated. When screens
  change materially, re-view the new screenshots and update the `SCREENS` /
  `BACKLOG` data so the report stays accurate.
- Competitor apps can't run in the Simulator (App Store binaries + live logins),
  so their half is always research-based, not live-captured.
- Pixel measurement of screenshots (margins, clipping) can be done with PIL —
  useful for catching layout bugs while capturing.
