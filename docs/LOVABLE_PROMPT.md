# Lovable prompt pack — CALL-ANALYZER frontend

Everything needed to generate the UI in Lovable and hand it back for wiring.

---

## 0. What Lovable actually generates (verified, Sept 2026)

| Layer | What Lovable produces |
|---|---|
| Language | **TypeScript** |
| Framework | **React 18** |
| Build tool | **Vite** |
| Styling | **Tailwind CSS** |
| Components | **shadcn/ui** (Radix primitives) |
| Routing | **React Router** |
| Icons | **lucide-react** |
| Charts | **Recharts** (its default when you ask for charts) |
| Backend | **Supabase by default** ← the thing we must switch off |

That last row is the whole reason this pack is written the way it is. Left to
its own devices Lovable will create Supabase tables, write its own queries, and
build the UI against a schema it invented. Merging that into our real schema
would be a rewrite, not an integration.

So every prompt below states, in capitals and more than once: **do not create or
connect to Supabase.** All data flows through one hand-written file,
`src/lib/api.ts`, whose types mirror our live FastAPI schema exactly.

### How to use this pack

1. **Paste Part 1 into Lovable's Knowledge / Project Context box** (Settings →
   Knowledge). Lovable re-reads this on every message, which is what stops it
   drifting back to Supabase halfway through.
2. **Paste the whole of `frontend/src/lib/api.ts`** as your first chat message,
   prefixed with: *"This is the API contract. Save it as `src/lib/api.ts`. Every
   network call in this app must go through it."*
3. **Then send Prompt 1.** Wait for it to finish and look right.
4. **Then Prompt 2, 3, 4** in order, one at a time.

Do not paste all four prompts at once. Lovable produces noticeably better work
on focused instructions, and a five-page single-shot generation is painful to
correct.

### If the build agent asks for the spec again and then stops

This happens when a prompt invites it to confirm understanding first: Lovable's
build agent treats that as a question, answers it, and ends the turn without
writing code. Every prompt here therefore opens with an explicit "build this
now, do not ask questions" instruction.

If it still stalls, the cause is almost always that the build agent did not
inherit the chat history. Re-send the prompt as ONE self-contained message with
the api.ts contents included inline, rather than referring back to an earlier
message.

---

## Part 1 — Knowledge file

> Paste this into **Settings → Knowledge** in Lovable, before any prompt.

```
# CALL-ANALYZER — Project Knowledge

## What this product is
An AI-powered customer support call intelligence platform. Support teams
generate thousands of call transcripts. Managers have no scalable way to review
them. CALL-ANALYZER automatically scores every call against a weighted quality
rubric using a five-agent AI pipeline, and makes every score explainable down to
the exact sentence in the transcript that justified it.

## Who uses it
- **Admin** — owns the quality rubric, sees every team, runs evaluations.
- **Manager** — reviews their own team's calls, coaches agents, triages
  compliance flags. This is the primary user; design for them.
- **Agent** — sees only their own calls and scores.

## The domain, in one paragraph
A "call" has a transcript split into speaker "turns". A "framework" (rubric) is
a three-level tree: Sections → Sub-sections → Criteria, each with a percentage
weight. An "evaluation" scores one call against one framework version, producing
a score per criterion, rolled up through sub-sections and sections into a final
percentage and an A–F grade. Two criteria are marked CRITICAL — failing either
one forces the whole call to 0% ("auto-fail"). Some criteria can be marked "not
applicable" when the situation never arose.

## CRITICAL TECHNICAL CONSTRAINTS — these override everything else

1. **DO NOT create, connect to, enable, or query Supabase.** Do not create
   database tables. Do not use the Supabase client. The backend already exists
   as a separate FastAPI service. This app is a pure API client.
2. **ALL data comes from `src/lib/api.ts`.** Import from it. Never write `fetch`
   anywhere else in the codebase.
3. **DO NOT invent fields.** If a value is not in the TypeScript types in
   api.ts, the backend does not return it. Render an empty state instead of
   fabricating data.
4. **DO NOT redefine the types** in api.ts. Import them.
5. During UI development, `api.ts` has `export const MOCK = true` and serves
   fixtures with identical shapes. Build against those.

## Three domain rules the UI must respect

1. **A not-applicable criterion renders as "N/A", never as 0.** The backend
   removes it from the weighted total entirely. Showing 0 misrepresents the
   agent's performance.
2. **An auto-failed call shows 0% together with its reason.** Never display a
   bare unexplained zero.
3. **Citation highlighting uses stored character offsets** (`char_start`,
   `char_end`), never a text search for the quoted string. The AI paraphrases
   when it quotes, so searching fails. The offsets are guaranteed exact against
   `transcript.full_text`.

## Product tone
A serious, information-dense analytics tool that a support manager stares at for
hours. Calm, precise, trustworthy. Not a marketing site. No hero sections, no
decorative illustrations, no gradient-filled cards, no emoji in the UI.
```

---
## Part 2 — Prompt 1: design system, app shell, dashboard

> Send this after pasting `api.ts`.

```
Build the foundation and the dashboard for CALL-ANALYZER.

BUILD THIS NOW. Do not ask clarifying questions, do not ask me to re-supply the
specification, and do not pause for confirmation — everything you need is in
this message. If a detail is genuinely unspecified, choose a sensible default,
note it in one line at the end, and keep building.

## STACK
React 18 + TypeScript + Vite, Tailwind CSS, shadcn/ui, React Router,
TanStack Query (react-query), Recharts, lucide-react, date-fns.

## ═══ DESIGN SYSTEM ═══

Set these exact CSS variables in src/index.css. Do not substitute your own
palette. This is a deliberate, tested colour system.

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 224 20% 12%;
    --card: 0 0% 100%;
    --card-foreground: 224 20% 12%;
    --popover: 0 0% 100%;
    --popover-foreground: 224 20% 12%;
    --primary: 243 75% 59%;
    --primary-foreground: 0 0% 100%;
    --secondary: 220 14% 96%;
    --secondary-foreground: 224 20% 20%;
    --muted: 220 14% 96%;
    --muted-foreground: 220 9% 46%;
    --accent: 220 14% 96%;
    --accent-foreground: 224 20% 20%;
    --destructive: 0 72% 51%;
    --destructive-foreground: 0 0% 100%;
    --border: 220 13% 91%;
    --input: 220 13% 91%;
    --ring: 243 75% 59%;
    --radius: 0.625rem;

    /* Semantic data colours — meaning, not decoration.
       Three variants each, because one value cannot serve all three jobs:
         -text : darkened to pass WCAG AA (4.5:1) as TEXT on the page
         (base): the fill for bars, chart series and badge backgrounds
         -soft : a tint for highlighted transcript turns and callouts
       Emerald and amber at their natural brightness measure 2.6:1 and 2.1:1 on
       white — they FAIL as text. Score numbers are text, so they use -text. */
    --success: 160 84% 39%;
    --success-text: 160 84% 28%;
    --success-soft: 152 76% 94%;
    --warning: 38 92% 50%;
    --warning-text: 32 95% 36%;
    --warning-soft: 48 100% 94%;
    --danger: 0 72% 51%;
    --danger-text: 0 72% 45%;
    --danger-soft: 0 86% 96%;
    --neutral-data: 220 9% 46%;

    /* Categorical chart series */
    --chart-1: 243 75% 59%;
    --chart-2: 173 80% 36%;
    --chart-3: 38 92% 50%;
    --chart-4: 340 82% 58%;
    --chart-5: 258 90% 66%;
    --chart-6: 199 89% 48%;
  }

  .dark {
    --background: 224 24% 7%;
    --foreground: 210 20% 96%;
    --card: 224 20% 10%;
    --card-foreground: 210 20% 96%;
    --popover: 224 20% 10%;
    --popover-foreground: 210 20% 96%;
    --primary: 243 80% 68%;
    --primary-foreground: 224 24% 7%;
    --secondary: 223 18% 16%;
    --secondary-foreground: 210 20% 96%;
    --muted: 223 18% 16%;
    --muted-foreground: 218 12% 65%;
    --accent: 223 18% 18%;
    --accent-foreground: 210 20% 96%;
    --destructive: 0 84% 62%;
    --destructive-foreground: 210 20% 98%;
    --border: 223 18% 19%;
    --input: 223 18% 19%;
    --ring: 243 80% 68%;

    /* On the dark background these already measure 9.9:1, 11.3:1 and 5.3:1,
       so text and fill can share a value. */
    --success: 158 64% 52%;
    --success-text: 158 64% 52%;
    --success-soft: 161 84% 12%;
    --warning: 43 96% 56%;
    --warning-text: 43 96% 56%;
    --warning-soft: 35 92% 12%;
    --danger: 0 84% 62%;
    --danger-text: 0 84% 62%;
    --danger-soft: 0 63% 14%;
    --neutral-data: 218 12% 65%;

    --chart-1: 243 80% 68%;
    --chart-2: 172 66% 50%;
    --chart-3: 43 96% 56%;
    --chart-4: 340 82% 66%;
    --chart-5: 258 90% 74%;
    --chart-6: 199 89% 60%;
  }
}

Extend tailwind.config.ts so all of these are usable as Tailwind classes:
bg-success, text-success-text, bg-success-soft, and the same for warning and
danger, plus chart-1 through chart-6.

**Use the right variant.** Any COLOURED NUMBER OR LABEL uses the `-text`
variant. Bars, chart series and badge fills use the base. Highlight tints use
`-soft`. This is not stylistic fussiness: at their natural brightness emerald
measures 2.6:1 and amber 2.1:1 against white, both well below the 4.5:1 minimum,
so a score rendered in the base colour is genuinely hard to read.

Solid badges: `bg-danger` takes white text (4.8:1, passes). `bg-success` and
`bg-warning` do NOT — give those foreground-coloured text, or use the soft
background with `-text` foreground instead.

### Typography
- UI font: **Inter** (via Google Fonts), weights 400/500/600/700.
- Numeric font feature: apply `font-variant-numeric: tabular-nums` globally to
  every number in a table or KPI, so columns of figures align.
- Monospace: **JetBrains Mono** for call codes, criterion codes, and IDs only.
- Base size 14px. Page titles 20px/600. Card titles 14px/600. KPI values
  30px/700. Table body 13px.

### Spacing and shape
- Card radius 10px (--radius). Buttons and inputs 8px. Badges fully rounded.
- Card padding 20px. Grid gap 16px. Page padding 24px.
- Borders: 1px solid hsl(var(--border)). Shadows ONLY on popovers, dropdowns and
  dialogs — cards use borders, not shadows.

### THE SCORE COLOUR RULE (used identically everywhere)
score >= 80  -> success  (text: text-success-text, bar: bg-success)
score 60-79  -> warning  (text: text-warning-text, bar: bg-warning)
score <  60  -> danger   (text: text-danger-text,  bar: bg-danger)
not applicable -> muted-foreground, never red, never zero
auto-fail -> solid danger badge, always with the reason text

Never use colour as the only signal. Always pair it with a number, label or
icon, for accessibility and for greyscale printing.

## ═══ APP SHELL ═══

Left sidebar, 240px, collapsible to 64px icons, state persisted to
localStorage:
- Top: a small waveform/audio-lines icon in primary, wordmark "CALL-ANALYZER"
  in 15px/700 with tight letter-spacing.
- Nav items with lucide icons: LayoutDashboard "Dashboard" (/),
  PhoneCall "Calls" (/calls), SlidersHorizontal "Framework" (/admin),
  MessageSquareText "Assistant" (/chat).
- Active item: primary-tinted background, primary left border 2px, medium weight.
- Bottom: theme toggle (Sun/Moon, persisted to localStorage), then a user chip
  with initials avatar, name, and a small role badge.

Header bar on every page: page title on the left, the global filter bar on the
right, and a muted "Updated {relative time}" caption.

### Global filter bar — one shared component
State lives in the URL query string so a filtered view can be copied and shared.
- Date range: presets "Last 7 days", "Last 30 days", "Last 6 weeks" (DEFAULT),
  "All time", plus a custom range picker.
- Team select — from api.teams.list().
- Agent select — from api.analytics.agents(), filtered to the chosen team.
- "Reset" button, visible only when a filter is active.
- Active filters render as removable chips beneath the bar.

Every page reads these and passes them straight into its API calls.

Routes /admin and /chat: render a centred card, "Coming in the next phase".
Build the nav entries, not the pages.

## ═══ PAGE: DASHBOARD (route /) ═══

Data: api.analytics.* — see api.ts for exact types.

### Row 1 — six KPI cards (grid: 6 cols desktop, 3 tablet, 2 mobile)
Source: api.analytics.overview(filters) -> AnalyticsOverview

Each card: muted 12px uppercase label with letter-spacing, then a 30px/700
value, then a sub-line. Trend arrow chip in the top-right.

| Label | Value | Sub-line |
|---|---|---|
| AVERAGE SCORE | current.avg_score, "54.2%" | trend from change_pct.avg_score |
| CALLS EVALUATED | current.evaluated_calls | "{evaluation_coverage_pct}% of {total_calls}" |
| AUTO-FAIL RATE | auto_fail_rate, "14.6%" | "{current.auto_fails} calls" — card border turns danger above 10% |
| CRITICAL FLAGS | current.critical_flags | "{current.total_flags} total flags" |
| SENTIMENT RECOVERY | current.avg_sentiment_delta, "+0.43" | "closing minus opening" |
| ACTIVE AGENTS | current.active_agents | "{formatDuration(avg_duration_seconds)} avg call" |

Trend arrows: green up / red down for score and sentiment. INVERT for auto-fails
and flags, where fewer is better. When change_pct.X is null, render an em-dash
"—" and no arrow. Null means there is no comparable prior period; rendering
"0%" would be a false statement.

### Row 2 — score trend (full width card)
Source: api.analytics.trend({...filters, granularity})

Recharts ComposedChart:
- Bars: `calls` on the right Y axis, fill hsl(var(--muted-foreground)) at 15%
  opacity, no stroke.
- Line: `avg_score` on the left Y axis fixed 0–100, stroke chart-1, 2.5px,
  dot only on hover, activeDot r=5.
- Optional dashed line: `avg_sentiment` rescaled to 0–100, chart-2, toggled by a
  legend checkbox, off by default.
- Header: title "Quality trend" plus a segmented Day / Week / Month toggle,
  defaulting to Week.
- CartesianGrid: horizontal lines only, border colour, strokeDasharray 3 3.
- Custom tooltip card showing every metric for that bucket including auto_fails.
- Empty state: "No calls in this period."

### Row 3 — two cards, 50/50
**Left, "Where we're weakest"** — api.analytics.sections()
Horizontal bars. The API already returns weakest-first; PRESERVE that order, it
is the entire point of the chart. Each row: section name, a bar coloured by the
score rule, the percentage right-aligned in 15px/600, and the section weight as
a small muted chip ("25% weight"). Clicking a row navigates to
/calls?sort_by=score&sort_dir=asc.

**Right, "Score distribution"** — api.analytics.distribution()
Bar chart over `bands`. RENDER ALL TEN BANDS INCLUDING EMPTY ONES — the API
returns them deliberately so the x-axis stays stable; filtering them out
misrepresents the shape. Colour each bar by the score rule. Beneath, a compact
A/B/C/D/F tally row with counts.

### Row 4 — two cards, 60/40
**Left, "Agent leaderboard"** — api.analytics.agents()
Sortable table: Agent (name, with agent_code muted beneath), Team chip, Calls,
Avg score (coloured, 15px/600), Consistency, Auto-fails, Sentiment Δ.

For Consistency render a small horizontal range bar spanning min_score to
max_score with a marker at avg_score, and the σ value (score_stddev) beside it.
This distinction matters: a steady 78 and an erratic 60–95 average the same but
are completely different coaching problems. Tooltip: "Lower σ means more
consistent." Row click → /calls?support_agent_id={id}.

**Right, "Coaching priorities"** — api.analytics.criteria({ limit: 8 })
Already worst-first. Per row: criterion_name in 13px/600; section_code /
subsection_code as a muted breadcrumb above; a thin avg_score bar; fail_rate_pct
as bold danger text on the right; a solid danger "CRITICAL" badge when
is_critical. Where not_applicable > 0, a muted footnote "N/A on {n} calls".

### Row 5 — two cards, 50/50
**Left, "Open risk flags"** — api.analytics.flags({ limit: 8 })
A row of severity chips from by_severity (critical=danger solid, high=danger
outline, medium=warning, low=muted). Then recent_open as a list: severity badge,
title in 13px/600, then "{call_code} · {agent_name} · {relative time}" muted.
Row click opens that call. Empty state: "No open flags."

**Right, "Topics"** — api.analytics.topics()
Table: topic (formatted from snake_case to Title Case), calls, avg score
(coloured), avg sentiment as a small −1..+1 diverging bar. Click →
/calls?topic={topic}.

## ═══ BEHAVIOUR ═══
- TanStack Query for every call. staleTime 30000. Query keys include the filters.
- Loading: skeletons shaped like the real content. Never a full-page spinner.
- Errors: catch ApiError from api.ts. If err.isConflict (409), show err.message
  VERBATIM in a destructive Alert — the backend writes those sentences for
  humans and paraphrasing removes the actionable part. Otherwise a generic
  message with a Retry button.
- Empty states everywhere, each with a specific sentence saying what is missing.
- Responsive down to 375px.
- Keyboard accessible: visible focus rings, Escape closes overlays.
- Formatting: scores to one decimal place with "%", token counts with thousands
  separators, dates as "2 Sep, 14:22", relative times as "3 days ago".

## ═══ MOCK DATA — use these real values ═══
84 calls, 9 agents, 3 teams: "Billing & Payments", "Technical Support",
"Retention & Loyalty".
Agents: Priya Nair, Rahul Menon, Sneha Kulkarni, Arjun Deshmukh, Fatima Sheikh,
Vikram Iyer, Ananya Bose, Karan Malhotra, Meera Raghavan.
Call codes look like NW-20260830-0077.
Overall average 54.2%. Grades: C 13, D 38, F 33. 12 auto-failed calls, all with
reason "Critical criterion failed: Verifies customer identity".
Sections and weights: OPENING 15%, COMMUNICATION 25%, RESOLUTION 30%,
COMPLIANCE 20%, CLOSING 10%.
Section averages: COMMUNICATION 42.6, RESOLUTION 48.7, OPENING 70.2,
CLOSING 72.4, COMPLIANCE 87.8.
Weakest criteria: PLAIN_LANGUAGE 1.2%, JARGON_AVOIDANCE 1.2%,
SOLUTION_ACCURACY 14.3%, ROOT_CAUSE_ID 18.5%.
Topics: retention 31 calls, billing 31, technical 21.
41 risk flags: 3 critical, 29 high, 9 medium.
Weekly trend: 5, 17, 17, 12, 13, 15, 5 calls with averages 48.0, 54.5, 55.5,
57.5, 50.8, 52.8, 60.9.

## DELIVERABLE
A working Vite + React + TypeScript project with the design system applied, the
app shell, and the dashboard. Clean structure under src/components/ (ui/,
charts/, layout/) and src/pages/. api.ts untouched apart from MOCK fixtures.
```

---
## Part 3 — Prompt 2: calls list and call drill-down

> Send after Prompt 1 is finished and looks right.

```
Add two pages. Do not modify the design system, the app shell, or the dashboard.
Reuse the existing global filter bar, score colour rule, and card styles.

## ═══ PAGE: CALLS (route /calls) ═══
Data: api.calls.list(filters) -> Paginated<CallOverview>

A dense, fast table. This is the workhorse screen — favour information density
over whitespace here.

### Filter row (above the table, state in the URL)
- Search input with a Search icon. Placeholder: "Search call code, agent, or
  transcript text…". Debounce 300ms. Tooltip: "Searches inside transcript
  content, not just metadata." (It genuinely does — the backend runs full-text
  search over transcripts.)
- Grade multi-select A–F.
- Score range: a dual-handle slider 0–100.
- Status select.
- Two toggle chips: "Has flags", "Auto-failed only".
- Active filters appear as removable chips.

### Columns
| Column | Content |
|---|---|
| Call | call_code in JetBrains Mono 12px; started_at relative, muted, beneath |
| Agent | agent_name 13px/500; agent_code muted beneath |
| Team | small outline chip |
| Duration | formatDuration(duration_seconds) |
| Score | 16px/700 coloured by the score rule + grade pill. If auto_fail_triggered, replace entirely with a solid danger badge reading "AUTO-FAIL" and show 0% beside it |
| Sentiment | label badge + sentiment_delta with ↑/↓, green/red |
| Flags | count badge; solid danger when critical_flag_count > 0; render nothing when 0 |
| Summary | headline, truncated to one line, muted |

- Sortable headers mapping to sort_by / sort_dir (started_at, score, duration,
  agent, sentiment).
- Server-side pagination with limit/offset, page-size select 25/50/100, and a
  "Showing 1–25 of 84" caption.
- Row hover: subtle accent background, cursor pointer.
- Loading: 10 skeleton rows that match the column widths, so the layout does not
  jump.
- Two distinct empty states: "No calls have been ingested yet" versus "No calls
  match these filters" (the latter with a "Clear filters" button).
- Row click → /calls/{call_id}.

## ═══ PAGE: CALL DRILL-DOWN (route /calls/:callId) ═══
Data: api.calls.get(callId) -> CallDetail. ONE request returns everything.

THIS IS THE MOST IMPORTANT PAGE IN THE PRODUCT. It is where the platform proves
its scores are trustworthy rather than magic.

### Header band
Back link "← Calls". Then call_code (mono, 18px), and a muted metadata row:
agent name · team · date · duration · channel.

Right side: a large score block — the percentage at 36px/700 coloured by the
rule, the grade pill beneath.

If auto_fail_triggered: instead render a full-width destructive Alert directly
under the header, with an AlertTriangle icon, the heading "Auto-fail", and the
auto_fail_reason text. The score still shows 0%, but never alone — an
unexplained zero is exactly what this product exists to prevent.

### Summary strip (full width card, under the header)
From `summary`: headline as 15px/600, summary as body text, then a chip row for
resolution_status, customer_intent, and each topic. If next_actions is
non-empty, a small checklist below: action, owner, due.

### Main layout: two columns, 58% / 42%, stacking to one column below 1024px

═══ LEFT COLUMN — TRANSCRIPT ═══

A stats strip at the top, from `statistics`, as five compact tiles:
- Agent talk ratio as a percentage with a mini progress bar. Amber above 75%,
  tooltip "Agent dominated the conversation".
- Questions asked · Interruptions detected · Agent turns · Customer turns.

Then the turn list, in a scrollable container with a sticky header:
- Agent turns: left-aligned, bg-muted, rounded, max-width 88%.
- Customer turns: right-aligned, bg-primary at 8% opacity with a primary left
  border, max-width 88%.
- Each turn: speaker_label in 11px/600 uppercase muted, then the text at 13px.
  Show start_ms as "m:ss" in the corner when present.
- Give every turn `id={`turn-${turn.turn_index}`}` so other panels can scroll
  to it.

★★★ CITATION HIGHLIGHTING — the single most important interaction ★★★

When the user selects a criterion in the right column, every turn that criterion
cited must highlight:

- Read the `citations` array on that CriterionScore.
- For each citation, find the turn where `turn.turn_index === citation.turn_index`.
- Apply a background tint to that turn: success-soft for polarity "supporting",
  danger-soft for "detracting", with a 2px left border in the matching solid
  colour.
- Smooth-scroll the first highlighted turn into view.
- Show a floating chip pinned to the top of the transcript panel: "Showing
  evidence for: {criterion_name}" with an X to clear.
- For sub-turn precision, use the exported helper highlightSegments(fullText,
  ranges) with char_start/char_end.

**NEVER search the transcript text for citation.quoted_text.** The AI
paraphrases when it quotes, so a text search silently fails and highlights
nothing. Use turn_index and the stored char offsets, which the backend
guarantees are exact.

═══ RIGHT COLUMN — five tabs ═══

**Tab 1 — Scores** (default)
An accordion grouped by section. Join section_scores, subsection_scores and
criterion_scores on section_code / subsection_code.

- Section header row: section_name 14px/600, `normalized * 100` as a coloured
  percentage, a muted weight chip, and a thin progress bar. Expanded by default.
- Sub-section rows: indented 16px, same treatment at 13px, plus a muted
  "{criteria_scored}/{criteria_total} scored" caption.
- Criterion rows: indented 32px.
  - Left: criterion_name at 13px. A solid danger "CRITICAL" badge when
    is_critical_snapshot.
  - Right: formatScore(score) from api.ts, a confidence dot (a small circle
    filled proportionally to `confidence`, tooltip "Model confidence: 72%"), and
    a citation-count badge with a Quote icon.
  - **Clicking the row highlights that criterion's citations in the transcript
    and marks the row as selected with a primary ring.**
  - Expanding shows `reasoning` as body text, then each citation as a blockquote
    with a left border in its polarity colour, the quoted text, and a "Jump to
    turn {n}" link that scrolls the transcript.
  - When is_applicable is false: render a muted "N/A" chip instead of a score,
    with na_reason as the tooltip, and grey the row back. NEVER render 0 —
    the backend excludes it from the weighted total, so 0 would be a false
    statement about the agent.

**Tab 2 — Sentiment**
Recharts AreaChart of sentiment_timeline: x = turn_index, y = score fixed
−1 to +1. Draw a ReferenceLine at y=0. Tint the area above zero success and
below zero danger (use two Area series with gradient fills, or split at zero).
Clicking a point scrolls the transcript to that turn.

Beneath, three stat tiles: Opening, Closing, and Delta (large, signed, coloured)
plus a trajectory badge ("recovered" gets a success badge — it means the agent
turned an angry customer around, which is the strongest positive signal in the
product).

**Tab 3 — Flags**
Cards from risk_flags: severity badge, title 13px/600, description, a confidence
bar, and the quoted_text as a blockquote with "Jump to turn {n}". Acknowledged
flags render muted with a Check icon. Empty state: "No risks flagged."

**Tab 4 — Pipeline**
A vertical timeline of agent_runs ordered by step_order. This tab exists to
prove five distinct AI agents ran, rather than one prompt with headings — make
it look convincing.

Each step: a connector line and status dot (success/danger/muted), agent_name in
13px/600, and a muted metadata row: model · {latency_ms}ms ·
{input_tokens}→{output_tokens} tokens. When attempt_count > 1, an amber chip
"retried ×{n}" with tooltip "The model was rate-limited or timed out; the
provider retried automatically."

Footer row: total tokens, total latency, and the model(s) used.

**Tab 5 — History**
Table from evaluation_history: date, score, grade, trigger_reason (formatted:
"initial" → "Initial evaluation", "framework_change" → "Rubric changed",
"manual_rerun" → "Manual re-run", "model_upgrade" → "Model upgraded"),
model_used, and a primary "Current" badge where is_current.

This answers a real question: did this agent's score change because they
improved, or because we changed the rubric?

## DELIVERABLE
Both pages, reusing the existing design system. No new dependencies beyond what
Prompt 1 installed.
```

---
## Part 4 — Prompt 3: framework admin panel

> Send after Prompt 2. This page is the project's headline feature — the rubric
> is editable by a business user with no code change.

```
Add the Framework admin panel at /admin. Do not modify existing pages.

## THE CONCEPT — read this before designing the UI

The quality rubric is a three-level tree: Sections → Sub-sections → Criteria,
each with a percentage weight. Weights must total 100 at EVERY level.

Rubrics are VERSIONED and copy-on-write:
- Exactly one version is `published` at a time. A published version is
  IMMUTABLE — the backend refuses to edit it and returns HTTP 409.
- Editing happens on a `draft`. Calling api.framework.draft() returns the
  existing draft, or clones the published version into a new one.
- Publishing validates the weights, archives the previous version, and promotes
  the draft — atomically.

So the UI must never attempt to PATCH a published version. Always call
api.framework.draft() first, and make it visible which version is being edited.

## ═══ LAYOUT ═══

### Version bar (sticky, top of page)
- Left: version_no and name, plus a status badge — published = success solid,
  draft = warning outline, archived = muted.
- Middle: when editing a draft, live validation from
  api.framework.validate(versionId), polled after every edit (debounced 500ms):
  - Valid → a success chip "Weights balanced" with a Check icon.
  - Invalid → a warning chip "{n} issue(s)" that opens a popover listing each
    issue's `issue` sentence, grouped by `level`.
- Right: buttons — "Auto-balance" (api.framework.normalize), "Publish"
  (disabled with a tooltip while invalid), and a version-history dropdown from
  api.framework.versions().

When viewing a published version, replace the edit controls with a single
prominent "Edit framework" button that calls api.framework.draft() and shows a
toast: "Editing draft v{n} — the published version is unchanged."

### The tree editor (main area)
A nested, collapsible tree. Each level is visually distinct through indentation
and left border colour, not through boxes inside boxes.

**Section row** — 48px tall, left border 3px chart-1:
- Drag handle (GripVertical), expand chevron.
- code in mono 11px muted; name in 14px/600, editable inline on click.
- Weight: a compact number input with a "%" suffix, 72px wide.
- An enable/disable Switch. Disabled rows render at 50% opacity with a muted
  "Disabled" chip.
- A muted count: "{n} sub-sections · {m} criteria".
- Row actions on hover: add sub-section, duplicate, delete.

**Sub-section row** — indented 24px, left border 2px chart-2, same controls.

**Criterion row** — indented 48px, left border 2px muted. This is the leaf and
carries the most:
- name, and a solid danger "CRITICAL" badge when is_critical.
- A scoring_type chip: "0–5", "0–10", "Met / Not met", "Numeric".
- Weight input.
- Enable Switch.
- Clicking opens the criterion editor in a right-hand Sheet (see below).

**Weight validity, shown inline.** Beside each parent, show the sum of its
enabled children's weights. Render it success when it equals 100, danger
otherwise, e.g. "100%" or "112% ⚠". This is the single most useful affordance on
the page — the user should never have to hunt for which level is unbalanced.

Drag-and-drop reordering within a level, persisted via
api.framework.reorder(level, items).

### Criterion editor (right Sheet, 520px)
Fields, in this order:
1. **Name** — text input.
2. **Code** — mono input, uppercase, disabled when editing an existing
   criterion (codes are how scores are matched across versions).
3. **Description** — short textarea. Helper: "What this measures, for humans."
4. **★ Scoring guidance** — a LARGE textarea, minimum 10 rows, monospace,
   character count shown. This is the most important field on the entire page.
   Label it "Scoring guidance (sent to the AI)". Helper text: **"This text is
   sent to the AI model verbatim. Editing it changes how every future call is
   scored — no code deployment needed."** Give it a subtle primary-tinted
   background so it reads as special, because it is: this field is the
   product's core claim.
5. **Scoring type** — select: Met/Not met (binary), 0–5, 0–10, Numeric.
   Show max_score and min_score inputs only when Numeric is chosen.
6. **Weight** — number input with a live "of 100% in this sub-section" caption.
7. **Critical (auto-fail)** — a Switch inside a danger-tinted callout box:
   "Failing this criterion forces the entire call score to 0%. Use only for
   regulatory or policy requirements."
8. **Allow not-applicable** — a Switch. Helper: "Lets the AI mark this criterion
   N/A when the situation never arose, instead of scoring it zero."
9. **Examples** — an optional repeatable list of {score, example, why} rows,
   used as few-shot anchors for the AI.

Footer: Cancel / Save. Save calls api.framework.updateCriterion.

### Publish flow
Clicking Publish opens a confirmation Dialog:
- Heading "Publish version {n}?"
- A validation summary (must be all-clear to proceed).
- A body explaining: "This version becomes the active rubric. The current
  published version will be archived. Historical scores keep referencing the
  version they were computed under and will not change."
- Confirm calls api.framework.publish(versionId). On 409, show err.message
  verbatim in a destructive alert — it names the exact unbalanced level.

### ★ After publishing: the "apply to history" step
On success, show a follow-up Dialog — this is the project's best demo moment:

"Apply this rubric to existing calls?"
Body: "Re-weighting is instant and free. Only genuinely new criteria need the
AI to re-read transcripts."
Buttons: "Not now" / "Apply to history" → api.framework.apply(versionId).

Render the ReprojectResult prominently:
- A large success line: "{recomputed_instantly} evaluations recomputed instantly
  — 0 AI calls, no cost."
- If queued_for_rescoring > 0, a second warning line: "{n} queued for re-scoring
  because this version added new criteria."

This distinction is the core architectural claim of the project. Make it look
like the achievement it is.

### Version history dropdown
Lists all versions from api.framework.versions(): version_no, name, status
badge, criterion_count, and evaluation_count. Selecting one opens it read-only.
Warn on any version where evaluation_count > 0 that scores reference it.

## DELIVERABLE
The admin page, reusing the existing design system.
```

---

## Part 5 — Prompt 4: manager assistant (chat)

> Send last. The backend for this lands in Phase 7 — build the UI against the
> mock so it is ready.

```
Add the Assistant at /chat. Do not modify existing pages.

A manager-facing chat that answers questions over call transcripts and scores.

## LAYOUT
Two columns: a 260px session sidebar, and the conversation.

**Sidebar**: "New conversation" button, then session list with title and
relative time. Active session highlighted.

**Conversation**: messages centred at max-width 760px.
- User messages: right-aligned, primary-tinted bubble.
- Assistant messages: left-aligned, no bubble — plain text on the page
  background, rendered as markdown, so long answers read like a document rather
  than a chat balloon.
- Streaming: a blinking caret while generating.

**★ Grounding — the anti-hallucination affordance**
Every assistant answer carries citations. Beneath each answer render:
- A muted caption: "Based on {n} calls".
- Citation cards in a horizontal scroll: call_code (mono), agent name, and the
  matched excerpt truncated to two lines. Clicking opens that call in a new tab.
- When the answer used a SQL aggregation, a collapsible "How I calculated this"
  section showing the generated SQL in a syntax-highlighted mono block.

This matters because it is the difference between a chatbot and an analytics
tool: the manager can verify every number.

**Composer**: auto-growing textarea, Enter to send, Shift+Enter for newline,
send button, and a stop button while streaming.

**Empty state**: heading "Ask about your calls", then four clickable example
prompts:
- "Which agents scored lowest on empathy this week?"
- "Show me calls where the customer mentioned billing issues"
- "What are the most common reasons for auto-failure?"
- "Summarise the biggest coaching opportunity for the Technical Support team"

Mock the responses for now, with realistic citations drawn from the seeded data.

## DELIVERABLE
The chat page, reusing the existing design system.
```

---

## Part 6 — Integration

### Verification checklist — run before sending it back

- [ ] No `supabase` import anywhere in the project
- [ ] No `fetch(` outside `src/lib/api.ts`
- [ ] The types in `api.ts` are unmodified
- [ ] Citation highlighting uses `turn_index` / `char_start` / `char_end`, never
      a text search for `quoted_text`
- [ ] N/A criteria render as "N/A", never as 0
- [ ] Auto-failed calls always show the reason alongside the 0%
- [ ] The distribution histogram renders all ten bands, empty ones included
- [ ] `change_pct: null` renders as "—", not "0%"
- [ ] Both light and dark themes look correct
- [ ] It builds: `npm run build` succeeds with no TypeScript errors

Run this in the project root to check the first two mechanically:

```bash
grep -rn "supabase" src/ || echo "clean: no supabase"
grep -rn "fetch(" src/ --include=*.tsx --include=*.ts | grep -v "lib/api.ts" || echo "clean: no stray fetch"
```

### Handing it back

Send me the exported zip or the GitHub repo link. Wiring it to the live backend
is then:

1. `export const MOCK = false;` in `src/lib/api.ts`
2. `VITE_API_URL=http://localhost:8000` in `.env`
3. Fix any component that drifted from the contract

That is genuinely the whole integration — which is the entire reason these
prompts forbid stray `fetch` calls and Supabase access.

### If Lovable ignores the Supabase rule anyway

It sometimes does, because Supabase is its default. If you see it create tables
or a Supabase client, reply:

> Stop. Remove all Supabase code, the client, and any tables you created. This
> app has an existing FastAPI backend. ALL data must come from `src/lib/api.ts`.
> Do not create a database.

Then re-send the affected prompt.

---

## Sources for the stack claims in Part 0

- [Lovable Tech Stack & Security Architecture Explained (2026)](https://vibe-eval.com/guides/lovable-tech-stack/)
- [Prompting best practices — Lovable Academy](https://academy.lovable.app/academy/prompting)
- [The Lovable Prompting Bible](https://lovable.dev/blog/2025-01-16-lovable-prompting-handbook)
- [Frontend Development Isn't Just UI — Lovable](https://lovable.dev/blog/frontend-development-with-lovable)
