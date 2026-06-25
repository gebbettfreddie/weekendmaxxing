# Weekendmaxxing — UX improvement backlog

Derived from a screen-by-screen audit of the app (see `report.html`) benchmarked
against Tinder, Hinge, and Skyscanner (see `competitors.md`). Priority = impact ×
confidence; effort is a rough build estimate.

## P0 — high impact, do first

| # | Improvement | Why | Source | Effort |
|---|---|---|---|---|
| 1 | **Remove the "API usage" debug card from the Alerts tab** | It surfaces internal request counts / proxy stats to end users — reads as unfinished and leaks implementation detail. | — (bug) | XS |
| 2 | **Add "Everywhere / Surprise me" to Search** | Skyscanner's signature funnel inversion ("what's cheap?" not "where?") — and it's exactly your swipe-deck value prop, missing from manual search. | Skyscanner | M |
| 3 | **Per-trip price alerts** | Today alerts are only a global "deals under £150". Let a *matched* trip be watched and push on its price drop — the highest-relevance re-engagement moment. | Skyscanner | M |
| 4 | **Reveal savings on the card + celebration** | Show "£57 · £40 below usual" using `typicalPrice`. Credible value/urgency without manufactured timers. | Skyscanner | S |

## P1 — strengthen the core loop & retention

| # | Improvement | Why | Source | Effort |
|---|---|---|---|---|
| 5 | **Undo / rewind last swipe** | Removes fast-swipe anxiety ("bring back that £25 Porto"); natural future upsell. | Tinder | S |
| 6 | **Daily fresh-deck framing + return hook** | "Deals refresh at 9am" gives a reason to return; reconsider the punitive "3 likes left" cap for a *deal* app (caps suit dating monetization, not bargain-hunting). | Tinder | S–M |
| 7 | **Upgrade the match celebration** | Add motion/confetti, a Share button, a "Set price alert" CTA, and time the App Store rating prompt to this peak moment. | Tinder | M |
| 8 | **Best / Cheapest / Fastest sort on flight detail** | One-tap price/time trade-off with a smart "Best" default; avoids paralysis. | Skyscanner | S |
| 9 | **Make Matches a decision tool** | Add price-change-since-save, enable compare; drop the meaningless "Destination" tag and the sparse single-row empty feel. | Skyscanner | M |
| 10 | **Actionable empty/out-of-deals states** | Deck-exhausted and Search-empty should offer a next step (widen budget, add Friday, see popular) + a return reason — never a dead end. | Tinder + Hinge | S–M |

## P2 — differentiation & longer-term

| # | Improvement | Why | Source | Effort |
|---|---|---|---|---|
| 11 | **"Like a facet" reactions** | Let users react to the £ price / 2hr flight / vibe, not just the whole card — far richer recommender signal. | Hinge | L |
| 12 | **"Did you book? / Worth it?" outcome loop** | Close the loop after a trip's date; feed real outcomes back into picks; signals you optimize for great trips. | Hinge | L |
| 13 | **Standouts: weekly curated "best deals"** | A separate algorithm-picked feed with credible expiry ("won't last"). Social proof + honest scarcity. | Hinge | M–L |
| 14 | **Playful prompt-style onboarding** | Replace dry filters with prompts ("Beach or city? Party or peace?"); shorten/justify the 7 steps; preview a live deck to cut abandonment. | Hinge | M |
| 15 | **Honest trade-off framing on cards** | "£19 — 2 stops, 9hr" vs "£44 direct, 2hr" builds trust and aids the swipe. | Skyscanner | S |
| 16 | **Variable-reward deck sequencing** | Intersperse the occasional jaw-dropping deal unpredictably so each swipe carries anticipation. | Tinder | S–M |
| 17 | **Stat-driven nudge microcopy** | "Trips booked within 2 days of matching are 40% cheaper" beats generic prompts. | Hinge | S |
