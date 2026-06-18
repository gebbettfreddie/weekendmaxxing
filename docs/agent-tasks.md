# Multi-agent task plan

This captures the parallel-agent setup for Weekendmaxxing so it can be picked up
later (e.g. in Claude Code). See `AGENTS.md` at the repo root for build commands,
architecture, and the parallel-work seams.

## Setup already done

- WIP committed to `main` as a checkpoint (worker proxy, Match feature, AGENTS.md).
- Two git worktrees created off that checkpoint, each on its own branch:

| Worktree path | Branch | Agent |
| --- | --- | --- |
| `../weekendmaxxing-worktrees/worker-offers` | `feat/worker-offers` | A — Worker |
| `../weekendmaxxing-worktrees/serp-client` | `feat/serp-client` | B — Service |

> Worktrees live *outside* the repo (siblings), so they are not committed here.
> Recreate them if missing:
> ```bash
> git worktree add -b feat/worker-offers ../weekendmaxxing-worktrees/worker-offers main
> git worktree add -b feat/serp-client   ../weekendmaxxing-worktrees/serp-client   main
> ```
> Then seed gitignored files per worktree:
> - serp-client: `cp Config/Secrets.xcconfig <wt>/Config/` then `xcodegen generate` in it
> - worker-offers: `cd <wt>/worker && npm install` (and create `.dev.vars`)

## Deliverable for this round

Complete **round-trip live offers**: add the inbound leg via SerpApi's two-step
`departure_token` flow, and badge live SerpApi offers as `.live` (they currently
default to `.cached`, so they're mislabelled "Indicative").

## Frozen contract (shared by Agent A and Agent B)

```
Endpoint: GET {PROXY}/v1/offers   (Cloudflare Worker -> SerpApi engine google_flights)
Auth header: X-App-Token: <APP_TOKEN>
Request params (whitelisted, forwarded to SerpApi minus api_key):
  departure_id, arrival_id, outbound_date, return_date, type, travel_class,
  adults, children, stops, max_price, currency, hl, gl, deep_search,
  + departure_token   <-- THE ONE ADDITION for round trips
Response: transparent passthrough of SerpApi google_flights JSON. Relevant shape:
  {
    "best_flights":  [ Flight ],
    "other_flights": [ Flight ]
  }
  Flight = {
    "flights": [ { "departure_airport": {"id","time"},
                   "arrival_airport":   {"id","time"},
                   "duration", "airline", "flight_number" } ],
    "total_duration", "price",
    "departure_token"   // present on first-call results; pass it back to get return legs
    "booking_token"     // present on second-call (return) results
  }
Two-step: first call returns outbound options each with departure_token.
  A second call with the same params + departure_token returns the RETURN options.
Cache: KV, TTL 3h, header X-Cache: HIT|MISS. Cache key is the sorted param set,
  so departure_token calls cache independently and correctly.
```

The only contract change is adding `departure_token` (and surfacing `booking_token`).
The worker stays a transparent passthrough, so A and B can build in parallel.

## Agent A — Worker

Worktree `../weekendmaxxing-worktrees/worker-offers`, branch `feat/worker-offers`,
**Agent mode**.

```
You are working in the git worktree at
/Users/freddie.gebbett/Documents/Dev/weekendmaxxing-worktrees/worker-offers
on branch feat/worker-offers. Read AGENTS.md at the repo root first.

DELIVERABLE: Enable the SerpApi google_flights two-step (round-trip) flow through
the proxy so the app can fetch return legs.

SCOPE — touch ONLY:
  worker/src/index.ts   (and worker/README.md if docs need it)
Do NOT touch any Swift code, project.yml, or Config/.

TASKS:
1. Add "departure_token" to ALLOWED_PARAMS so it is forwarded to SerpApi.
2. Confirm the existing cache-key logic (params.sort() then join) still produces a
   stable, unique key when departure_token is present — it should; verify, don't
   rewrite the caching.
3. Make sure return-call payloads (which carry booking_token) are cached the same
   way as first-call payloads (200 + no "error" field).
4. Update worker/README.md's /v1/offers row/example to mention departure_token.

FROZEN CONTRACT: see the contract block — the worker remains a transparent
passthrough of SerpApi google_flights JSON. Do not reshape responses.

SETUP/VERIFY:
- worker/.dev.vars is gitignored and absent here; create it with SERPAPI_KEY and
  APP_TOKEN (copy from the main checkout at
  /Users/freddie.gebbett/Documents/Dev/weekendmaxxing/worker/.dev.vars) to run live.
- Run: cd worker && npm run dev  (serves localhost:8787, validates the script).
- Smoke test with curl: a /v1/offers call, then a second call adding
  departure_token=<value from the first response>, and confirm you get return legs
  and X-Cache flips HIT on repeat.

DONE WHEN: departure_token round-trips through the proxy and caches correctly;
README updated; npm run dev starts clean. Commit on feat/worker-offers. Do not merge.
```

## Agent B — Service

Worktree `../weekendmaxxing-worktrees/serp-client`, branch `feat/serp-client`,
**Agent mode**.

```
You are working in the git worktree at
/Users/freddie.gebbett/Documents/Dev/weekendmaxxing-worktrees/serp-client
on branch feat/serp-client. Read AGENTS.md at the repo root first.

DELIVERABLE: Populate the round-trip INBOUND leg on live offers, and badge live
SerpApi offers correctly as .live.

SCOPE — touch ONLY:
  Weekendmaxxing/Services/SerpApi/SerpApiTripService.swift
(If you must add a shared type, ask first — avoid editing Models/ so you don't
collide with the UI.)
Do NOT touch worker/, project.yml, AppConfig.swift, or any Features/ views.

CONTEXT (current state of SerpApiTripService.offers):
- It calls /v1/offers, reads best_flights + other_flights, builds the OUTBOUND
  Itinerary only, and returns TripOffer with inbound: nil.
- TripOffer.source is NOT set, so it defaults to .cached — WRONG for live data.

TASKS:
1. Add departure_token (and booking_token) to the private SerpFlightsResponse DTO.
2. After the first /v1/offers call, for each outbound Flight with a departure_token,
   make a SECOND /v1/offers call with the same query items + departure_token, parse
   its best_flights/other_flights, build the inbound Itinerary, and set it on the
   TripOffer. Run the second calls with bounded concurrency (reuse the withTaskGroup
   batching pattern from TripService.swift; cap ~4) and tolerate per-offer failures
   (keep the outbound-only offer if the return call fails).
3. Set source: .live on every TripOffer this service produces.
4. If a booking_token is available, you may surface it, but do NOT change TripOffer's
   shape — bookingURL already falls back to Skyscanner.

FROZEN CONTRACT: see the contract block. Decode the documented snake_case fields via
the existing convertFromSnakeCase decoder. Assume the worker is a transparent
passthrough; you can build/mock against the contract before Agent A merges.

VERIFY (own DerivedData so builds don't collide with other worktrees):
  cd /Users/freddie.gebbett/Documents/Dev/weekendmaxxing-worktrees/serp-client
  xcodegen generate   # already generated, re-run only if you add/rename files
  xcodebuild -project Weekendmaxxing.xcodeproj -scheme Weekendmaxxing \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -derivedDataPath .build/dd build

DONE WHEN: round-trip offers carry a non-nil inbound, source is .live, and the build
succeeds. Commit on feat/serp-client. Do not merge.
```

## Agent C — Explore (read-only)

Run against `main` (no worktree), **Ask mode**.

```
READ-ONLY exploration. Make NO edits. Repo:
/Users/freddie.gebbett/Documents/Dev/weekendmaxxing (branch main).

GOAL: De-risk two in-flight changes — (a) populating TripOffer.inbound for live
offers, and (b) setting TripOffer.source = .live on SerpApi results.

Produce a written report covering:
1. Every call site of TripService.offers(...) and AppConfig.makeTripService(), and
   how the HybridTripService offers path is wired (who ends up calling SerpApi).
2. Everywhere TripOffer.inbound is read in the UI (e.g. OfferDetailView,
   OfferRow, TripDetailView/TripDetailViewModel, SearchViewModel): does any code
   ASSUME inbound is nil, or would it render/break differently once inbound is set?
3. Everywhere OfferSource / .source / dataSource is consumed (badges, notes,
   filtering, sorting). Confirm switching SerpApi offers from .cached to .live only
   changes badging and has no other behavioural side effects.
4. Any total-duration / stops / price logic that changes once a round-trip inbound
   exists (e.g. totalDurationMinutes, isDirect).

Output: a concise findings list with file:line references and a short "safe / watch
out" verdict for each of the two changes. Do not modify anything.
```

## Run order & merge

1. Kick off A and B in parallel; run C alongside and feed its findings to B.
2. When both are green, from `main`:
   ```bash
   git merge feat/worker-offers
   git merge feat/serp-client
   ```
3. No `AppConfig` change needed — `makeTripService()` already routes offers through
   `SerpApiTripService`. Build once on `main` to confirm the integrated path.
4. Tear down a worktree when done:
   `git worktree remove ../weekendmaxxing-worktrees/worker-offers`
