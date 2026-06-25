#!/usr/bin/env python3
"""Assemble the UX-audit report (self-contained HTML with embedded screenshots).

Reads tools/ux-audit/shots/app/*.png, downscales + base64-embeds them, and
renders a per-screen critique + prioritized backlog into report.html.
"""
import base64, io, os, html
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, "shots", "app")
OUT = os.path.join(HERE, "report.html")

def data_uri(path, width=360, quality=78):
    im = Image.open(path).convert("RGB")
    h = int(im.height * width / im.width)
    im = im.resize((width, h), Image.LANCZOS)
    buf = io.BytesIO(); im.save(buf, "JPEG", quality=quality)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()

# Per-screen critique. (file, title, works[], improve[(text, source)])
SCREENS = [
    ("01-onboarding-vibe.png", "Onboarding · Vibe",
     ["Clear single question, big chips, visible 'Step 1 of 7' progress.",
      "Selected state is unambiguous (filled + check)."],
     [("7 steps is long — Tinder gets users swiping 'in minutes'. Justify or trim.", "Tinder"),
      ("Framing is functional; lean into playful prompts ('Beach or city? Party or peace?').", "Hinge"),
      ("No preview of the payoff — show a live deck peek to cut first-run abandonment.", "Tinder")]),
    ("03-onboarding-budget.png", "Onboarding · Budget",
     ["Plain-language question, single slider, sensible default ('Under £200')."],
     [("Could echo Skyscanner's flexibility framing ('flexible dates = cheaper').", "Skyscanner"),
      ("Consider showing how many destinations that budget unlocks, live.", "Skyscanner")]),
    ("04-onboarding-notifications.png", "Onboarding · Notifications",
     ["Value-first headline ('Catch price drops'); honest about what's watched."],
     [("Hard system ask with thin value-stack — quantify it ('save £X on average').", "Hinge"),
      ("Offer a 'maybe later' path so a decline doesn't feel terminal.", "Tinder")]),
    ("05-match-deck.png", "Match · Swipe deck",
     ["Strong Tinder-style card; price correctly hidden until the match reveal.",
      "Redundant tap buttons (pass / super / like) back up the swipe gesture.",
      "Clean header with picks-remaining context."],
     [("No undo/rewind — add one to remove fast-swipe anxiety.", "Tinder"),
      ("'3 likes left today' is a punitive cap; suits dating monetization, not a deal app. Reframe as a daily-refresh hook.", "Tinder"),
      ("No first-run gesture hint / SAVE-PASS stamp is subtle; make the mid-drag affordance bolder.", "Tinder"),
      ("Sequence an occasional jaw-dropping deal unpredictably for variable reward.", "Tinder")]),
    ("06-match-celebration.png", "Match · Celebration",
     ["The designed peak moment: breaks the theme (white → coral), reveals city + price.",
      "Clear next steps ('View trip' / 'Keep swiping'); 'Saved to your trips' sets expectation."],
     [("Add motion (confetti/spring), a Share button, and a 'Set price alert' CTA.", "Tinder+Skyscanner"),
      ("Time the App Store rating prompt to this happiest moment.", "Tinder"),
      ("Show the saving vs typical fare to amplify the win ('£40 below usual').", "Skyscanner")]),
    ("07-trip-detail.png", "Trip detail",
     ["Honest 'Indicative prices' caveat builds trust (meta-search style).",
      "Flight rows show Direct + duration — real trade-off info.",
      "Clear hero, dates, nights, and a single primary action."],
     [("No Best/Cheapest/Fastest sort on the flight list.", "Skyscanner"),
      ("No 'Set price alert' here — capture intent at the moment of interest.", "Skyscanner"),
      ("'Save destination' duplicates the swipe match — clarify the relationship.", "—"),
      ("Make the cheap-but-long vs direct trade-off explicit per option.", "Skyscanner")]),
    ("08-search.png", "Search",
     ["Fast weekend chips ('This / Next weekend'); live-price promise is clear."],
     [("No 'Everywhere / Surprise me' — Skyscanner's signature funnel inversion is missing.", "Skyscanner"),
      ("No cheapest-weekend / flexible-date discovery view.", "Skyscanner"),
      ("Empty state is a near dead-end — seed it with popular/cheap inspiration.", "Tinder+Hinge")]),
    ("09-alerts.png", "Deal alerts",
     ["Good event-driven concept ('ping you the moment…'); manual 'Check now' for the impatient."],
     [("The 'API usage' debug card leaks internal request counts to users — remove it.", "— (bug)"),
      ("Alerts are global ('under £150') only — add per-matched-trip price watches.", "Skyscanner"),
      ("Toggle defaults off with thin justification — stack the value to drive opt-in.", "Skyscanner")]),
    ("10-saved.png", "Matches (saved)",
     ["Consistent landing from the celebration; price shown 'from £54'."],
     [("It's a flat list, not a decision tool — add compare + price-change-since-save.", "Skyscanner"),
      ("The 'Destination' tag is meaningless filler — replace with useful signal.", "—"),
      ("Sparse single-row state feels empty — show momentum / a nudge to keep swiping.", "Tinder")]),
]

BACKLOG = [
    ("P0", [
        ("Remove the 'API usage' debug card from Alerts", "Leaks internal metrics; reads unfinished.", "bug", "XS"),
        ("Add 'Everywhere / Surprise me' to Search", "Skyscanner's funnel inversion = your core value prop.", "Skyscanner", "M"),
        ("Per-trip price alerts", "Watch a matched trip; push on its drop — highest-relevance ping.", "Skyscanner", "M"),
        ("Reveal savings on card + celebration", "'£57 · £40 below usual' via typicalPrice — credible value.", "Skyscanner", "S"),
    ]),
    ("P1", [
        ("Undo / rewind last swipe", "Removes fast-swipe anxiety; future upsell.", "Tinder", "S"),
        ("Daily fresh-deck framing + return hook", "'Refresh at 9am'; rethink the punitive likes cap.", "Tinder", "S–M"),
        ("Upgrade the match celebration", "Motion, Share, 'Set alert', timed rating prompt.", "Tinder", "M"),
        ("Best / Cheapest / Fastest flight sort", "One-tap trade-off, smart default.", "Skyscanner", "S"),
        ("Make Matches a decision tool", "Compare + price-change-since-save; drop filler tag.", "Skyscanner", "M"),
        ("Actionable empty / out-of-deals states", "Always a next step + a return reason.", "Tinder+Hinge", "S–M"),
    ]),
    ("P2", [
        ("'Like a facet' reactions", "React to price/flight-time/vibe — richer recommender signal.", "Hinge", "L"),
        ("'Did you book? / Worth it?' outcome loop", "Feed real outcomes back into picks.", "Hinge", "L"),
        ("Standouts: weekly curated best deals", "Social proof + credible expiry.", "Hinge", "M–L"),
        ("Playful prompt-style onboarding", "Prompts over filters; shorten; preview the deck.", "Hinge", "M"),
        ("Honest trade-off framing on cards", "'£19 — 2 stops, 9hr' vs '£44 direct'.", "Skyscanner", "S"),
        ("Variable-reward deck sequencing", "Intersperse wow deals for anticipation.", "Tinder", "S–M"),
        ("Stat-driven nudge microcopy", "Quantified nudges beat generic prompts.", "Hinge", "S"),
    ]),
]

def li(items, source=False):
    out = []
    for it in items:
        if source:
            text, src = it
            out.append(f'<li>{html.escape(text)} <span class="tag">{html.escape(src)}</span></li>')
        else:
            out.append(f'<li>{html.escape(it)}</li>')
    return "\n".join(out)

screen_html = []
for f, title, works, improve in SCREENS:
    uri = data_uri(os.path.join(SHOTS, f))
    screen_html.append(f"""
    <section class="screen">
      <div class="shot"><img src="{uri}" alt="{html.escape(title)}"></div>
      <div class="crit">
        <h3>{html.escape(title)}</h3>
        <p class="lbl works">What works</p>
        <ul class="works">{li(works)}</ul>
        <p class="lbl improve">What to improve</p>
        <ul class="improve">{li(improve, True)}</ul>
      </div>
    </section>""")

backlog_html = []
for pri, rows in BACKLOG:
    cls = {"P0":"p0","P1":"p1","P2":"p2"}[pri]
    items = "\n".join(
        f'<tr><td><span class="pri {cls}">{pri}</span></td><td><strong>{html.escape(t)}</strong><br><span class="muted">{html.escape(why)}</span></td><td><span class="tag">{html.escape(src)}</span></td><td class="eff">{html.escape(eff)}</td></tr>'
        for (t, why, src, eff) in rows)
    backlog_html.append(items)

DOC = f"""<title>Weekendmaxxing — UX Audit</title>
<style>
  :root {{ --bg:#0e0f13; --panel:#161821; --ink:#f4f5f7; --muted:#9aa0ad; --line:#262a36;
           --coral:#fb595c; --coral2:#ff8a6a; --green:#5fd08a; }}
  * {{ box-sizing:border-box; }}
  body {{ margin:0; background:var(--bg); color:var(--ink);
          font:16px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; }}
  .wrap {{ max-width:1040px; margin:0 auto; padding:56px 24px 96px; }}
  header.hero {{ border-bottom:1px solid var(--line); padding-bottom:28px; margin-bottom:8px; }}
  .kicker {{ color:var(--coral); font-weight:700; letter-spacing:.14em; text-transform:uppercase; font-size:12px; }}
  h1 {{ font-size:clamp(34px,6vw,56px); line-height:1.02; margin:.25em 0 .15em; letter-spacing:-.02em; }}
  .sub {{ color:var(--muted); max-width:62ch; }}
  .meta {{ display:flex; flex-wrap:wrap; gap:10px; margin-top:22px; }}
  .chip {{ background:var(--panel); border:1px solid var(--line); border-radius:999px; padding:6px 14px; font-size:13px; color:var(--muted); }}
  h2 {{ font-size:13px; letter-spacing:.16em; text-transform:uppercase; color:var(--muted);
        margin:64px 0 22px; padding-bottom:10px; border-bottom:1px solid var(--line); }}
  .screen {{ display:grid; grid-template-columns:200px 1fr; gap:28px; padding:26px 0; border-bottom:1px solid var(--line); }}
  .shot img {{ width:100%; border-radius:18px; border:1px solid var(--line); display:block; }}
  .crit h3 {{ margin:0 0 14px; font-size:21px; letter-spacing:-.01em; }}
  .lbl {{ font-size:11px; letter-spacing:.12em; text-transform:uppercase; margin:16px 0 6px; font-weight:700; }}
  .lbl.works {{ color:var(--green); }}
  .lbl.improve {{ color:var(--coral2); }}
  ul {{ margin:0; padding-left:18px; }} li {{ margin:5px 0; color:#dfe2e8; }}
  ul.works li {{ color:var(--muted); }}
  .tag {{ display:inline-block; font-size:11px; color:var(--coral); background:rgba(251,89,92,.12);
          border:1px solid rgba(251,89,92,.25); border-radius:6px; padding:1px 7px; margin-left:4px; white-space:nowrap; }}
  table {{ width:100%; border-collapse:collapse; }}
  td {{ border-bottom:1px solid var(--line); padding:14px 10px; vertical-align:top; }}
  td:first-child {{ width:46px; }} td.eff {{ width:54px; text-align:center; color:var(--muted); font-variant-numeric:tabular-nums; }}
  .muted {{ color:var(--muted); font-size:14px; }}
  .pri {{ font-weight:800; font-size:12px; padding:3px 8px; border-radius:6px; }}
  .pri.p0 {{ color:#fff; background:var(--coral); }}
  .pri.p1 {{ color:var(--coral); background:rgba(251,89,92,.14); }}
  .pri.p2 {{ color:var(--muted); background:var(--panel); border:1px solid var(--line); }}
  .group-label {{ margin:30px 0 6px; font-weight:700; color:var(--ink); }}
  footer {{ color:var(--muted); font-size:13px; margin-top:48px; border-top:1px solid var(--line); padding-top:20px; }}
  @media (max-width:640px) {{ .screen {{ grid-template-columns:1fr; }} .shot img {{ max-width:240px; }} }}
</style>

<div class="wrap">
  <header class="hero">
    <div class="kicker">UX Audit · Generated by the screenshot agent</div>
    <h1>Weekendmaxxing<br>vs. the apps it borrows from</h1>
    <p class="sub">Every screen of the app, walked automatically and screenshotted, then critiqued
    against the patterns that make Tinder, Hinge, and Skyscanner work. The competitor flows were
    researched from public teardowns — see <code>competitors.md</code>.</p>
    <div class="meta">
      <span class="chip">{len(SCREENS)} screens captured</span>
      <span class="chip">3 apps benchmarked</span>
      <span class="chip">{sum(len(r) for _,r in BACKLOG)} backlog items</span>
      <span class="chip">iPhone 17 · iOS Simulator</span>
    </div>
  </header>

  <h2>Screen-by-screen</h2>
  {''.join(screen_html)}

  <h2>Prioritized backlog</h2>
  <div class="group-label">P0 — high impact, do first</div>
  <table>{backlog_html[0]}</table>
  <div class="group-label">P1 — strengthen the core loop &amp; retention</div>
  <table>{backlog_html[1]}</table>
  <div class="group-label">P2 — differentiation &amp; longer-term</div>
  <table>{backlog_html[2]}</table>

  <footer>
    Re-run with <code>tools/ux-audit/capture-app.sh</code> then <code>build-report.py</code>,
    or the <code>/ux-audit</code> skill. Competitor research lives in <code>competitors.md</code>;
    the prioritized list is also in <code>backlog.md</code>.
  </footer>
</div>"""

with open(OUT, "w") as fh:
    fh.write(DOC)
print("wrote", OUT, f"({os.path.getsize(OUT)//1024} KB)")
