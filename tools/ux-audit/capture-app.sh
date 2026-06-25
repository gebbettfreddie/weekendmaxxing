#!/usr/bin/env bash
#
# UX-audit capture harness for Weekendmaxxing.
#
# Boots an iOS Simulator, builds + installs the app, then walks it through a set
# of "scenes" — each a launch configuration (UserDefaults state + launch args)
# that lands the app on a specific screen — and screenshots each one to
# tools/ux-audit/shots/app/<NN-scene>.png.
#
# Interactive states (match celebration, trip detail, onboarding steps) are
# reached via the DEBUG-only UITestHooks launch args, so no taps are required.
#
# Usage:
#   tools/ux-audit/capture-app.sh [--sim "iPhone 17"] [--no-build]
#
set -euo pipefail

SIM="iPhone 17"
DO_BUILD=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim) SIM="$2"; shift 2 ;;
    --no-build) DO_BUILD=0; shift ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BID="com.weekendmaxxing.app"
OUT="$REPO/tools/ux-audit/shots/app"
mkdir -p "$OUT"
rm -f "$OUT"/*.png

echo "▶ Booting $SIM"
xcrun simctl bootstatus "$SIM" -b >/dev/null 2>&1 || xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl bootstatus "$SIM" -b >/dev/null 2>&1 || true
open -a Simulator || true

if [[ "$DO_BUILD" == "1" ]]; then
  echo "▶ Building"
  xcodebuild -project "$REPO/Weekendmaxxing.xcodeproj" -scheme Weekendmaxxing \
    -destination "platform=iOS Simulator,name=$SIM" -derivedDataPath "$REPO/.build/ux-audit" \
    build >/dev/null
fi
APP="$(find "$REPO/.build/ux-audit/Build/Products" -name 'Weekendmaxxing.app' -maxdepth 3 | head -1)"
if [[ -z "$APP" ]]; then
  # fall back to the default DerivedData location
  APP="$(find "$HOME/Library/Developer/Xcode/DerivedData" -name 'Weekendmaxxing.app' -path '*Debug-iphonesimulator*' 2>/dev/null | head -1)"
fi
echo "▶ Installing $APP"
xcrun simctl install "$SIM" "$APP"

# onboarding_done <true|false> : set the first-run completion flag
onboarding_done() {
  xcrun simctl spawn "$SIM" defaults write "$BID" preferences.completedOnboarding -bool "$1" >/dev/null 2>&1 || true
}

# shoot <name> <onboardingDone> <launch-args...> : configure state, launch, screenshot
shoot() {
  local name="$1"; shift
  local done="$1"; shift
  onboarding_done "$done"
  xcrun simctl terminate "$SIM" "$BID" >/dev/null 2>&1 || true
  xcrun simctl launch "$SIM" "$BID" "$@" >/dev/null
  sleep 4
  xcrun simctl io "$SIM" screenshot "$OUT/$name.png" >/dev/null 2>&1
  echo "  📸 $name"
}

echo "▶ Capturing scenes"
# Onboarding flow (fresh): first-run is forced by clearing the completion flag.
shoot "01-onboarding-vibe"          false -uiOnboardingStep 0
shoot "02-onboarding-regions"       false -uiOnboardingStep 1
shoot "03-onboarding-budget"        false -uiOnboardingStep 3
shoot "04-onboarding-notifications" false -uiOnboardingStep 6
# Main app (onboarding complete).
shoot "05-match-deck"        true -initialTab match
shoot "06-match-celebration" true -initialTab match -uiCelebrate
shoot "07-trip-detail"       true -initialTab match -uiRouteTopCard
shoot "08-search"            true -initialTab search
shoot "09-alerts"            true -initialTab alerts
shoot "10-saved"             true -initialTab saved

echo "✔ Done. Screenshots in $OUT"
ls -1 "$OUT"
