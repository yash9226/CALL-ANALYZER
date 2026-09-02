# Lovable prompt — CALL-ANALYZER frontend (Phase 5)

**How to use this file**

1. Copy everything between the `=== PROMPT START ===` and `=== PROMPT END ===`
   markers into Lovable as your first message.
2. When Lovable asks for the API contract, paste the **entire contents** of
   [`frontend/src/lib/api.ts`](../frontend/src/lib/api.ts) as your second
   message. (Or paste both at once if the input allows it.)
3. Export / download the generated project and hand it back — I will wire it to
   the live backend, which is a single-file change because everything routes
   through `api.ts`.

**Why the prompt is written this way.** Left alone, Lovable invents its own
Supabase tables and queries. Merging that into a real schema is miserable. So
the prompt forbids it and pins every network call to `api.ts`, whose types match
the live FastAPI schema exactly. That one constraint is what makes the handoff
a swap rather than a rewrite.

This prompt covers **Phase 5 only** — dashboard, calls list, call drill-down,
plus the app shell. The Admin panel (Phase 6) and Chat (Phase 7) are stubbed as
routes so navigation does not need rebuilding later; I will supply follow-up
prompts for those.

---

```
=== PROMPT START ===

Build a production-quality analytics dashboard for CALL-ANALYZER, an
AI-powered customer support call quality platform. Support managers use it to
review call transcripts that have been automatically scored against a weighted
quality rubric by a multi-agent AI pipeline.

## NON-NEGOTIABLE RULES

1. ALL data comes from `src/lib/api.ts`, which I am providing. Import from it.
   Never write a raw `fetch` anywhere else.
2. DO NOT create, connect to, or query Supabase. DO NOT create any database
   tables. The backend already exists. This app is a pure API client.
3. DO NOT invent fields. If a value is not in the TypeScript types in api.ts,
   the backend does not return it. Do not fabricate placeholder data to fill a
   chart. If something is missing, render an empty state.
4. Use the exact type names from api.ts. Do not redefine them.
5. Set `export const MOCK = true;` at the top of api.ts during development so
   the app renders without a backend, and build the fixtures to match the real
   shapes and the realistic values given below.

## TECH STACK

- React 18 + TypeScript + Vite
- Tailwind CSS + shadcn/ui components
- Recharts for all charts
- React Router for routing
- TanStack Query (react-query) for data fetching, with a 30s staleTime
- lucide-react for icons
- date-fns for date formatting

## DESIGN DIRECTION

Serious, information-dense, calm. This is a professional analytics tool that a
support manager stares at all day — not a marketing page. No gradients on cards,
no decorative illustrations, no oversized hero sections.

- Light and dark mode, toggled in the header, persisted to localStorage
- Base font size 14px; tabular numerals for all figures (`font-variant-numeric:
  tabular-nums`) so columns of numbers align
- Generous whitespace, 1px borders, subtle shadows only on overlays
- Neutral slate/zinc palette for chrome; colour reserved for data meaning

**Semantic colour, used consistently everywhere:**

| Meaning | Colour | Used for |
|---|---|---|
| Excellent (>=80) | emerald | scores, grade A/B |
| Satisfactory (60-79) | amber | scores, grade C/D |
| Poor (<60) | red | scores, grade F |
| Critical / auto-fail | red-600 with a solid badge | never subtle |
| Supporting evidence | emerald background tint | citation highlights |
| Detracting evidence | red background tint | citation highlights |
| Not applicable | zinc / muted | never red, never zero |

Never use colour as the only signal — pair it with a label or icon, for
accessibility.

## APP SHELL

Persistent left sidebar (collapsible to icons on small screens):
- Logo: "CALL-ANALYZER" with a waveform icon
- Nav: Dashboard (/), Calls (/calls), Framework (/admin) [stub], Assistant
  (/chat) [stub]
- Bottom: theme toggle, and a user chip showing name + role badge

Top header on every page: page title, a global filter bar, and a "Last updated"
timestamp.

**Global filter bar** — a single shared component whose state is held in the URL
query string so a filtered view can be copied and shared:
- Date range picker with presets: Last 7 days, Last 30 days, Last 6 weeks
  (default), All time
- Team dropdown (from `api.teams.list()`)
- Agent dropdown (from `api.analytics.agents()`), filtered by the selected team
- A "Reset" button, shown only when a filter is active

Every page reads these filters and passes them straight into the API calls.

Routes /admin and /chat render a simple centred "Coming in the next phase"
placeholder card. Build the nav entries, but not the pages.

---

## PAGE 1 — DASHBOARD (route: /)

### Row 1: six KPI cards
Data: `api.analytics.overview(filters)` -> `AnalyticsOverview`

| Card | Value | Sub-line |
|---|---|---|
| Average score | `current.avg_score` as `54.3%` | trend arrow from `change_pct.avg_score` |
| Calls evaluated | `current.evaluated_calls` | `evaluation_coverage_pct`% of `total_calls` |
| Auto-fail rate | `auto_fail_rate` as `14.6%` | `current.auto_fails` calls, red if > 10% |
| Critical flags | `current.critical_flags` | `current.total_flags` total flags |
| Sentiment recovery | `current.avg_sentiment_delta` as `+0.43` | "closing minus opening" |
| Active agents | `current.active_agents` | `formatDuration(current.avg_duration_seconds)` avg call |

Trend arrows: green up / red down for score, **inverted** for auto-fails and
flags (fewer is better). When `change_pct.X` is `null` render an em-dash "—",
never "0%" — null means there is no comparable prior period.

### Row 2: score trend chart (full width)
Data: `api.analytics.trend({...filters, granularity})` -> `TrendPoint[]`

Composed Recharts chart:
- Bars: `calls` per bucket, on a right-hand Y axis, muted zinc, low opacity
- Line: `avg_score`, on a left-hand Y axis (0-100), 2px, emerald
- Optional second line: `avg_sentiment` scaled to the same axis, dashed, toggled
  by a legend checkbox
- A day/week/month toggle in the card header, defaulting to week
- Rich tooltip showing every metric for that bucket, including `auto_fails`
- Empty state: "No calls in this period"

### Row 3: two cards side by side

**Left — Section performance** (`api.analytics.sections()` -> `SectionPerformance[]`)
Horizontal bar chart, already sorted weakest-first by the API — keep that order,
it is the point of the chart. Each row: section name, a bar coloured by score
band, the percentage, and the section weight as a muted chip (e.g. "25% weight").
Clicking a bar navigates to `/calls` filtered to that section's weakest calls.

**Right — Score distribution** (`api.analytics.distribution()` -> `ScoreDistribution`)
Histogram over `bands`. Render ALL TEN bands including empty ones — the API
returns them deliberately so the x-axis is stable. Colour each bar by its band.
Below it, a compact grade tally: A/B/C/D/F with counts.

### Row 4: two cards side by side

**Left — Agent leaderboard** (`api.analytics.agents()` -> `AgentScorecard[]`)
Sortable table: Agent (name + code), Team, Calls, Avg score (coloured), a
consistency indicator from `score_stddev`, Auto-fails, Sentiment delta.

For consistency show a small horizontal range bar from `min_score` to
`max_score` with a marker at `avg_score`, plus the σ value. This matters: a
steady 78 and an erratic 60-95 average the same but are completely different
coaching problems. Row click navigates to `/calls?support_agent_id=...`.

**Right — Coaching priorities** (`api.analytics.criteria({ limit: 8 })`)
The API returns worst-first. For each: criterion name, section as a muted
breadcrumb, `avg_score` as a small bar, `fail_rate_pct` as bold red text, and a
red "CRITICAL" badge when `is_critical`. Show `not_applicable` as a muted "N/A
on N calls" note where non-zero.

### Row 5: two cards side by side

**Left — Open risk flags** (`api.analytics.flags({ limit: 8 })` -> `FlagSummary`)
Severity chips at the top showing `by_severity` counts. Then a list of
`recent_open`: severity badge, title, call code, agent name, relative time.
Row click opens that call. Empty state: "No open flags — nice."

**Right — Topics** (`api.analytics.topics()` -> `TopicBreakdown[]`)
Table or treemap: topic, call count, avg score (coloured), avg sentiment. Topic
click navigates to `/calls?topic=...`.

---

## PAGE 2 — CALLS LIST (route: /calls)

Data: `api.calls.list(filters)` -> `Paginated<CallOverview>`

A dense, fast table. This is the workhorse screen.

**Filter bar** (in addition to the global one, state in the URL):
- Search box — placeholder "Search call code, agent, or transcript text…",
  debounced 300ms. Make clear in a tooltip that it searches transcript CONTENT,
  not just metadata.
- Grade multi-select (A-F)
- Score range slider (0-100)
- Status dropdown
- Toggles: "Has flags", "Auto-failed only"
- Active filters shown as removable chips above the table

**Columns:**

| Column | Content |
|---|---|
| Call | `call_code` (monospace) + relative `started_at` below |
| Agent | `agent_name` + `agent_code` muted |
| Team | `team_name` as a chip |
| Duration | `formatDuration(duration_seconds)` |
| Score | Large coloured number + grade pill. If `auto_fail_triggered`, show "0% AUTO-FAIL" as a solid red badge instead |
| Sentiment | Small badge from `sentiment_label`, plus `sentiment_delta` with a ↑/↓ arrow |
| Flags | Count badge, red when `critical_flag_count > 0`, hidden when zero |
| Summary | `headline`, truncated to one line |

- Sortable headers mapping to `sort_by` / `sort_dir`
- Server-side pagination using `limit` / `offset` with a page-size selector
  (25/50/100) and a "Showing X-Y of Z" caption
- Skeleton rows while loading, never a spinner that shifts layout
- Empty state distinguishes "no calls yet" from "no calls match these filters",
  the latter with a "Clear filters" button
- Row click opens `/calls/:callId`

---

## PAGE 3 — CALL DRILL-DOWN (route: /calls/:callId)   ★ the most important page

Data: `api.calls.get(callId)` -> `CallDetail`. ONE request returns everything.

### Header
Back link, `call_code`, agent, team, date, duration. On the right, a large score
display: percentage, grade pill, and — if `auto_fail_triggered` — a prominent
red banner reading "AUTO-FAIL: {auto_fail_reason}". An unexplained zero must
never appear.

### Below the header: summary strip
From `summary`: `headline` as a heading, `summary` as body text, then chips for
`resolution_status`, `customer_intent`, and each `topics` entry. If
`next_actions` is non-empty, a small checklist showing action / owner / due.

### Main layout: two columns, 60/40

**LEFT COLUMN — the transcript**

Render turns from `turns`. Agent turns left-aligned with a neutral background;
customer turns right-aligned with a tinted background. Show `speaker_label`, the
text, and `start_ms` as `m:ss` when present.

★ **CITATION HIGHLIGHTING — the core feature of this product.**

When the user selects a criterion in the right column, every turn cited by that
criterion must highlight, using the `citations` array on the `CriterionScore`:

- Use the helper `highlightSegments(fullText, ranges)` exported from api.ts, or
  match on `citation.turn_index`.
- Highlight with a background tint: emerald for `polarity: "supporting"`, red
  for `"detracting"`.
- Auto-scroll the first highlighted turn into view, smoothly.
- Show a small floating chip: "Showing evidence for: {criterion_name}" with an
  X to clear.

**NEVER search the transcript for `quoted_text` to find where to highlight.**
Use `char_start` / `char_end`, which the backend guarantees are exact offsets
into `transcript.full_text`. The quoted text may be a paraphrase and will not
always match.

Above the transcript, a small stats strip from `statistics`: agent talk ratio as
a percentage with a mini bar (amber above 75%, with the tooltip "Agent dominated
the conversation"), questions asked, interruptions detected, turn counts.

**RIGHT COLUMN — scores, in tabs**

*Tab 1: Scores* — an accordion grouped by section, using `section_scores`,
`subsection_scores` and `criterion_scores` (join them on `section_code` and
`subsection_code`).

- Section header: name, `normalized * 100` as a coloured percentage, the weight
  chip, and a progress bar. Expanded by default.
- Sub-section rows nested inside, same treatment, one level indented.
- Criterion rows: name, `formatScore(score)` from api.ts, a confidence dot
  (filled proportionally to `confidence`), and a citation count badge.
  - Clicking a criterion row highlights its citations in the transcript.
  - Expanding shows `reasoning`, and each citation as a quote block with its
    polarity colour and a "jump to turn" link.
  - `is_applicable === false` renders a muted "N/A" chip with `na_reason` as a
    tooltip. **Never render N/A as 0** — the backend excludes it from the total,
    and showing 0 misrepresents the agent.
  - `is_critical_snapshot` gets a red "CRITICAL" badge.

*Tab 2: Sentiment* — a line chart of `sentiment_timeline` (x = `turn_index`,
y = `score` from -1 to +1), with a zero reference line and the area under the
curve tinted red below zero and green above. Clicking a point scrolls the
transcript to that turn. Below it, three stats: opening, closing, and the delta
with a trajectory badge.

*Tab 3: Flags* — cards from `risk_flags`: severity badge, title, description,
confidence, and the quoted text with a jump link. If `is_acknowledged`, show it
muted with a check.

*Tab 4: Pipeline* — the demo-winning tab. A vertical timeline of `agent_runs`
ordered by `step_order`, each showing agent name, status icon, model, latency in
ms, token counts, and `attempt_count` when greater than 1 (annotated "retried —
the model was rate-limited"). Below it, totals: total tokens and a cost figure.
This proves five distinct agents ran, rather than one prompt with headings.

*Tab 5: History* — `evaluation_history` as a table: date, score, grade,
`trigger_reason`, `model_used`, and an "is current" marker. This is how a
manager sees whether a score changed because the agent improved or because the
rubric changed.

---

## BEHAVIOUR REQUIREMENTS

- TanStack Query for every call, with `staleTime: 30_000` and query keys that
  include the filters
- Skeleton loaders shaped like the real content; never a full-page spinner
- Error states: catch `ApiError`. For `err.isConflict` (409) show
  `err.message` verbatim in a destructive alert — the backend writes those for
  humans and paraphrasing loses the actionable part. For everything else show a
  generic message with a Retry button.
- Empty states everywhere, with a specific sentence explaining what is missing
- Fully responsive: the drill-down stacks to one column below 1024px
- Keyboard accessible: focus rings, escape closes overlays, tables navigable
- All numbers formatted consistently: scores to one decimal place with a
  trailing `%`, tokens with thousands separators

## REALISTIC MOCK DATA (use these values so the UI looks right)

- 84 calls, 9 agents, 3 teams: "Billing & Payments", "Technical Support",
  "Retention & Loyalty"
- Agent names: Priya Nair, Rahul Menon, Sneha Kulkarni, Arjun Deshmukh,
  Fatima Sheikh, Vikram Iyer, Ananya Bose, Karan Malhotra, Meera Raghavan
- Call codes look like `NW-20260830-0077`
- Overall average score 54.3%, ranging from 0 (auto-fails) to about 79
- Grade counts roughly: C 13, D 37, F 32
- 12 auto-failed calls, all with the reason "Critical criterion failed:
  Verifies customer identity"
- Sections and weights: OPENING 15%, COMMUNICATION 25%, RESOLUTION 30%,
  COMPLIANCE 20%, CLOSING 10%
- Section averages: COMMUNICATION 43.0%, RESOLUTION 49.1%, OPENING 70.2%,
  CLOSING 72.5%, COMPLIANCE 87.5%
- 31 criteria. Weakest: PLAIN_LANGUAGE 1.2%, JARGON_AVOIDANCE 1.2%,
  SOLUTION_ACCURACY 14.3%, ROOT_CAUSE_ID 18.5%
- Two critical criteria: RECORDING_DISCLOSURE, IDENTITY_VERIFICATION
- Topics: billing (31 calls), retention (31), technical (21)
- 39 risk flags: 3 critical, 27 high, 9 medium
- Agent runs per call: preprocessing, scoring, sentiment, risk, summary
- Transcripts are telecoms support calls about duplicate charges, internet
  outages, slow speeds, router setup, and cancellations. Turns look like:
  "Agent: Thank you for calling Northwind Broadband, my name is Priya, and this
  call is recorded for quality purposes." / "Customer: I have been charged twice
  for my FIBER-300 plan this month and I am really frustrated."

## DELIVERABLE

A complete, working Vite + React + TypeScript project with all three pages
built, `src/lib/api.ts` used as the single data layer, and mock fixtures that
match the real API shapes exactly. Clean component structure under
`src/components/` and `src/pages/`.

=== PROMPT END ===
```

---

## After Lovable generates it

Send me the project (zip, or the repo link). Wiring it to the live backend is:

1. `MOCK = false` in `api.ts`
2. `VITE_API_URL=http://localhost:8000` in `.env`
3. Replace any component that drifted from the contract

Because everything routes through `api.ts`, that is genuinely the whole
integration — which is exactly why the prompt is written to forbid stray
`fetch` calls and Supabase access.

## Verification checklist

Before you send it back, confirm:

- [ ] No `supabase` import anywhere
- [ ] No `fetch(` outside `src/lib/api.ts`
- [ ] `api.ts` types are unmodified
- [ ] Citation highlighting uses `char_start` / `char_end`, not text search
- [ ] N/A criteria render as "N/A", never as 0
- [ ] Auto-failed calls show the reason, never a bare 0%
- [ ] The distribution histogram shows all ten bands, including empty ones
