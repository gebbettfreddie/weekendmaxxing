# Mobile App UX Benchmark: Tinder, Hinge, Skyscanner

*Reference doc for "Weekendmaxxing" — a swipe-based weekend-flight-finder iOS app (swipe through cheap London weekend trips like a dating app; right-swipe = match = saved trip; "It's a match!" celebration; flight search, price/deal alerts, saved/matches tab).*

*Compiled from public design teardowns, UX case studies, app-store listings, and product blogs (June 2026). Citations inline.*

---

## 1. Tinder

### Core flows, screen by screen

- **Onboarding** — Deliberately minimal: register (phone/social), then a short profile build (photos, age, gender, name), a quick gesture tutorial, and you're swiping "in minutes." The design goal is to reduce cognitive load and get users to the core loop as fast as possible; the gesture demo (swipe left = Nope, right = Like) is taught in-context rather than via a wall of text.
- **Main loop** — A full-bleed **card stack**: one large lazy-loaded photo, name, age, city. The whole screen is the interaction surface — drag the card, or use the redundant Nope/Like/Super-Like buttons. Binary choice + infinite supply keeps the loop tight and "game-like."
- **Detail** — Tap to expand the card into the full profile (more photos, bio, prompts). Detail is opt-in, layered *under* the fast loop so it never slows down high-velocity swipers.
- **Conversion / match** — The **"It's a Match!"** screen: the normally-white app **goes dark**, both faces appear together, large stylized "It's a match!" text, plus CTAs to message now or keep swiping. It also embeds a **share button** and is the moment Tinder times its **app-store rating prompt** (ask when the user is happiest).
- **Retention hooks** — Daily like reset (24h after first swipe), push notifications ("New likes available, come meet your match"), Boost timers, and the match-celebration dopamine loop.

### Signature UX patterns and why they work

- **Swipe-as-primary-affordance** — A single physical gesture maps to a binary decision. It's faster than tapping, feels tactile/playful, and turns judgment into a flow state. The card *physically tilts and shows a NOPE/LIKE stamp* as you drag, giving real-time affordance feedback before you commit.
- **Variable-ratio reward (slot machine)** — Matches arrive on an unpredictable schedule ("sometimes 2 swipes, sometimes 20"). This intermittent reinforcement is the single biggest driver of compulsive swiping — the anticipation, not the match itself, fuels the loop.
- **The dark "It's a Match!" reveal** — Breaking the visual pattern (white → dark) marks the win-state as special and emotionally distinct from the grind of swiping. It's a designed peak moment.
- **Undo / Rewind as a paid scarcity lever** — Rewinding your last swipe is a premium feature; the *fear of having missed something good* is itself the conversion hook.
- **Super Like as scarcity signal** — One free Super Like signals "you stood out" (not desperation); they're capped and expire if unused, so scarcity drives both usage and upsell.
- **Daily like cap + countdown** — Free users get ~25–100 likes per 12h; hitting the wall produces a "you're out of gas" screen with a reset timer. The "torture break" makes the resource feel valuable and drives return visits / upgrades.

### Microcopy / tone

- **"It's a Match!"** — the canonical celebratory exclamation; short, joyful, second-person-implied.
- **NOPE / LIKE / SUPER LIKE** stamps that animate onto the card mid-drag.
- Out-of-likes screen framed around a **reset timer** ("come back in X") rather than a flat "no."
- Re-engagement push: **"New likes available — come meet your match."**

### Empty states, gamification, scarcity, notifications

- **Empty/out-of-resource state**: doubles as a paywall + countdown timer — never a dead end, always "wait, or upgrade."
- **Gamification**: binary choice, variable reward, match celebration, Boost (timed visibility multiplier with urgency countdown). Octalysis Core Drives 2 (Accomplishment), 5 (Social), 6 (Scarcity), 7 (Unpredictability).
- **Scarcity/urgency**: capped daily likes, expiring Super Likes, time-boxed Boost.
- **Notifications**: scheduled re-engagement timed to the like-reset and to new likes/matches.

---

## 2. Hinge

### Core flows, screen by screen

- **Onboarding** — Long, intentional profile build: multiple photos + answers to **Prompts** (e.g. "Two truths and a lie", "My simple pleasures"). The friction is the point — it forces personality into the profile so others have something specific to react to.
- **Main loop ("Discover")** — Not a swipe stack. You scroll **one profile at a time**, and crucially you **like a specific element** — a single photo or a specific prompt answer — rather than the whole person. You can attach a comment to the like.
- **Standouts** — A separate curated feed of "best potential matches" the algorithm predicts will like you back. In Standouts you **can only send Roses**, not regular likes — engineered scarcity that makes the feed feel premium.
- **Likes You** — Incoming likes inbox; **Roses surface at the top**, above regular likes, for prioritized visibility.
- **Conversion / match** — Mutual like opens a chat. Leaving a comment on a like makes you **3× more likely to get a response**; a Most Compatible match makes a date **8× more likely**.
- **Retention / closing the loop** — The **"We Met"** survey: ~4 days after numbers are exchanged, two questions — "Did you meet?" and "Would you see them again?" Hinge feeds this real-world outcome back into the matching algorithm.

### Signature UX patterns and why they work

- **"Designed to be deleted"** — The entire brand is built on getting users to *succeed and leave*. Counter-intuitively this builds trust and word-of-mouth: the product optimizes for outcome quality, not time-on-app.
- **Like-a-specific-thing** — Liking one photo or prompt forces specificity, gives the recipient a built-in conversation starter, and signals genuine attention vs. a low-effort blanket swipe. This is the antidote to swipe-fatigue and ghosting.
- **Prompts** — Structured personality scaffolding. They make profiles comparable, lower the blank-page burden, and generate the hooks that the like-a-thing mechanic depends on.
- **Roses as scarce signal** — One free Rose/week. Scarcity makes a Rose read as "I'm serious," and it gets prioritized placement in the recipient's inbox.
- **Standouts curated feed** — Algorithmic "best of," gated behind Roses-only. Combines social proof ("most popular") with FOMO ("not guaranteed to reappear, don't wait").
- **Most Compatible (Gale-Shapley)** — Matches on *mutual* likelihood, not just who you'd like: "not just who you are likely to like… also who is likely to like you back." Reduces one-sided dead ends.
- **"We Met" feedback loop** — Closing the loop on real-world outcomes lets the algorithm optimize for the true goal (good dates), and signals to the user that the app cares about results, not engagement.

### Microcopy / tone

- Tagline: **"The dating app designed to be deleted."**
- Conversational, personality-led **Prompts** ("Two truths and a lie…") that set a playful, low-stakes tone.
- **"We Met"** survey copy is warm and outcome-focused ("Did you two meet?").
- Stat-driven nudges that double as microcopy: "**8× more likely** to go on a date," "**3× more likely** to get a response with a comment."

### Empty states, gamification, scarcity, notifications

- **Gamification is deliberately soft** — no swipe-velocity loop; engagement comes from quality signals (Standouts, compatibility stats) rather than slot-machine reward.
- **Scarcity**: weekly free Rose; Roses-only Standouts feed; "don't wait, they may not reappear."
- **Notifications** lean toward meaningful events (new like, comment, Rose, Most Compatible drop) and the We-Met prompt — fewer, higher-signal pings consistent with the anti-addiction brand.

---

## 3. Skyscanner

### Core flows, screen by screen

- **Search entry** — From/To, dates, passengers. Two power moves live right in the search bar: leave **"To" = "Everywhere"** for destination discovery, and set dates to **"Whole month"** or **"Cheapest month"** for flexible-date discovery.
- **"Everywhere" results** — Enter only a departure airport; get a list of **destinations ranked cheapest → most expensive**, each with a sample price. Turns "I have a budget and no plan" into a browsable list.
- **Whole-month / cheapest-date view** — A **calendar grid showing a price per day**, so you can eyeball the cheapest day to fly at a glance (prices shown per leg).
- **Results list** — Sort tabs: **Best** (price + duration blend, the default), **Cheapest**, **Fastest**. Filters: direct-only, stops, departure/arrival time windows, specific airports, airlines. Layered so the default is sensible but power users can drill in.
- **Detail / booking** — Skyscanner is a meta-search aggregator: it compares providers and hands off to the airline/OTA to book. The trade-off surfaced to users: e.g. "cheapest takes twice as long but saves nearly $300."
- **Conversion** — **Price Alerts** ("Get Price Alerts" above results) and **Saved list** (heart icon) — both let users *defer* the booking decision rather than abandon it.

### Signature UX patterns and why they work

- **"Everywhere" search** — Inverts the funnel: instead of "where do you want to go?" it asks "what can you afford?" Perfect for inspiration-mode, budget-led travelers who don't have a fixed destination.
- **Cheapest-month / whole-month calendar** — Makes price *legible across time* at a glance, exposing that flexibility = savings. Color/price-per-day cues let users instantly spot the cheap day.
- **Best/Cheapest/Fastest tri-sort** — Acknowledges there's no single "best" — lets the user pick their own price/time trade-off in one tap, and "Best" gives a smart default so nobody is paralyzed.
- **Price Alerts** — Captures intent at the moment of interest and re-engages on a *price event* (a drop), which is the highest-relevance moment to ping someone about a flight.
- **Saved list (heart) + side-by-side compare** — A lightweight shortlist so users can compare top picks and "keep all your vacation plans organized" without committing.
- **Honest trade-off framing** — Showing the cost of saving (longer journey, more stops) builds trust in a meta-search where the user ultimately books elsewhere.

### Microcopy / tone

- **"Everywhere"** as a literal, inviting search value — one word that reframes the whole product.
- **"Show whole month"**, **"Cheapest month"**, **"extra flexible with dates"** — plain, helpful, traveler-friendly.
- **"Get Price Alerts"** — clear, value-first CTA.
- Inspirational, deal-hunting tone throughout ("snag a great price the moment airfare drops," "book your dream trip without overpaying").

### Empty states, gamification, scarcity, notifications

- **Low gamification** by comparison — value comes from data clarity, not reward loops. The "Everywhere" list and per-day price calendar *are* the engagement hook.
- **Scarcity/urgency** is real-world and credible: prices genuinely move, so "book the moment the fare drops" creates urgency without manufactured pressure.
- **Notifications**: price-drop alerts (push + email) tied to saved routes/dates — event-driven, high-relevance, opt-in.

---

## Transferable to Weekendmaxxing

Concrete patterns worth stealing/adapting, tagged by source. Ordered roughly by impact.

1. **Card-stack swipe loop for trips** *(Tinder)* — Each card = one weekend trip (hero destination photo, city, dates, round-trip price). Swipe right = save/match, left = pass. The dating-app gesture is the whole product hook; make the card the full interaction surface with a mid-drag "SAVE / PASS" stamp.
2. **Dark "It's a Match!" celebration on save** *(Tinder)* — Break the visual theme (flip to a dark, confetti, large "It's a match!" moment) when a user right-swipes a trip. Show the destination + price reunited, and CTAs: "Set a price alert" / "Keep swiping." This is your peak moment — design it deliberately.
3. **Variable-reward sequencing of cards** *(Tinder)* — Don't sort strictly cheapest-first. Intersperse the occasional jaw-dropping deal ("£19 to Lisbon!") unpredictably in the stack so each swipe carries anticipation. The intermittent "wow" deal is what keeps people swiping.
4. **"Everywhere" as the default trip feed** *(Skyscanner)* — The home loop should *be* "Everywhere from London this weekend, cheapest first," reframed as a swipeable deck. Inverts the funnel from "where?" to "what's cheap?" — exactly your value prop.
5. **Cheapest-weekend / flexible-date framing on cards** *(Skyscanner)* — Each card shows the cheapest specific weekend for that destination, with a tappable "other weekends" mini-calendar showing price-per-weekend. Flexibility = savings, made legible.
6. **Price-event push notifications** *(Skyscanner)* — Re-engage on a *price drop* for a saved/matched trip ("Your Barcelona weekend just dropped to £38"), not on a timer. Highest-relevance ping; mirrors Tinder's event-driven "new likes" but with honest real-world urgency.
7. **Saved/Matches tab as a comparable shortlist** *(Skyscanner + Tinder)* — Your "matches" tab = Skyscanner's Saved list. Let users compare matched trips side-by-side (price, dates, flight time) so the tab is a decision tool, not just a graveyard of saves.
8. **Best / Cheapest / Fastest sort for the deck** *(Skyscanner)* — Let users re-sort the swipe deck by Cheapest, Shortest flight, or a "Best" blend. Smart default ("Best"), one-tap power. Avoids paralysis while serving power users.
9. **Undo last swipe** *(Tinder)* — A rewind button for "wait, that £25 Porto trip — bring it back." Cheap to build, removes the anxiety of fast swiping, and is a natural premium upsell later.
10. **Super-Like equivalent: "Lock this deal" / Rose** *(Tinder + Hinge)* — One scarce, high-intent action per week that pins a deal and starts active price-watching it. Scarcity makes it feel meaningful and is a clean monetization lever.
11. **Like-a-specific-thing for trips** *(Hinge)* — Let users react to a *facet* of a trip, not just the whole card — tap-to-like "the £39 price," "the 2hr flight," or "the food scene." Feeds your recommender far richer signal than a binary swipe and personalizes the next cards.
12. **"We Met" → "Did you book? / How was it?" loop** *(Hinge)* — After a matched weekend's date passes, ask two questions: "Did you go?" and "Worth it?" Closes the loop, feeds the recommender real outcomes, and signals the app optimizes for great trips, not endless swiping.
13. **Standouts: a curated "best deals this week" feed** *(Hinge)* — A separate, algorithm-picked feed of exceptional deals the user is likely to want, refreshed weekly with "won't last — don't wait" framing. Combines social proof + credible scarcity (deals genuinely expire).
14. **Prompts-style trip personality onboarding** *(Hinge)* — Onboarding asks playful prompts ("Beach or city?", "Party or peace?", "Max flight time?", "Budget per trip?") instead of dry filters. Lowers the blank-page burden and seeds personalization from card one.
15. **Daily fresh deck + reset hook** *(Tinder)* — "Your weekend deals refresh at 9am" gives a daily reason to return without a punitive cap. Re-engagement push tied to the refresh: "Fresh weekend escapes just landed."
16. **Honest trade-off framing on cards** *(Skyscanner)* — Show the cost of cheap: "£19 — but a 2-stop, 9hr journey" vs "£44 direct, 2hr." Builds trust (you're a deal-finder, not a trickster) and helps the swipe decision.
17. **Out-of-deals empty state that's a next step, never a dead end** *(Tinder + Hinge)* — When the deck is exhausted: "You've seen this weekend's best from London. Widen your budget? Add Friday departures? Come back at 9am for more." Always an action + a return reason.
18. **Match-screen rating/share prompt timing** *(Tinder)* — Trigger the app-store rating ask (and a "share this deal" button) on the "It's a match!" celebration — the user's happiest moment. Best-timed ask in the whole funnel.
19. **Scarce, credible urgency on deals** *(Skyscanner > Tinder)* — Use *real* price/seat volatility for urgency ("3 left at this price," "fare expected to rise") rather than manufactured timers. Honest urgency converts and protects trust.
20. **Comment/reason attached to a save** *(Hinge)* — Optionally let users tag *why* they saved a trip ("anniversary," "with mates"). Improves the matches tab, powers smarter future recommendations, and supports shareable group planning.
21. **"Designed to be deleted" ethos as brand** *(Hinge)* — Optimize for users actually *taking the trip*, not max swipe-time. Counter-intuitive, but it earns trust and word-of-mouth — the durable moat for a consumer travel app.
22. **Stat-driven nudges as microcopy** *(Hinge)* — Surface motivating stats inline: "Trips booked within 2 days of matching are 40% cheaper," "People who set an alert save £X on average." Quantified copy nudges action better than generic prompts.
23. **Layered detail under a fast loop** *(Tinder)* — Keep the swipe loop fast; tap-to-expand a card for full detail (all flight options, neighborhoods, weather). Never slow the core loop for the minority who want depth.

---

### Sources
- Tinder: redrocket.software teardown; psychologyinaction.org; Octalysis Group; auto-swiper.ch (like limits); roast.dating (Super Like)
- Hinge: Latana deep dive; Columbia CaseWorks ("designed to be deleted"); Hinge Help (Standouts); VIDA Select review; The Match Artist / roast.dating (Roses)
- Skyscanner: Skyscanner "Plan your trip" + Price Alerts tips; whole-month search guide; Going.com Skyscanner guide
