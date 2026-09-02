# CODEMAP — what every file does

The file-by-file reference for this repository. Updated at the end of every
phase, not bolted on at the end.

Read this top-to-bottom once and you will know where everything lives. For the
*why* behind the design, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

**Legend** — ✅ built and verified · 🚧 in progress · ⬜ planned

---

## Repository layout

```
CALL-ANALYZER/
├── supabase/              ✅ Database: migrations, seed data, tests
│   ├── migrations/           10 ordered SQL files — the whole schema
│   ├── seeds/                Generated seed data
│   ├── tests/                SQL assertions against the scoring engine
│   ├── seed.sql              Teams, agents, quality framework v1
│   └── config.toml           Local stack config (ports remapped to 544xx)
├── scripts/               ✅ Developer utilities
│   └── generate_seed_calls.py
├── backend/               ⬜ FastAPI app + agent pipeline   (Phase 2-4, 7)
├── frontend/              ⬜ React dashboard                (Phase 5-6)
├── docs/                  ✅ Architecture and report material
├── .env.example           ✅ Environment template
├── CODEMAP.md             ✅ This file
└── README.md              ✅ Setup and run instructions
```

---

## `supabase/migrations/` — the database

Ordered files. Each runs exactly once, in filename order. Never edit a migration
that has been applied to the cloud project; add a new one instead.

### `20260902000001_extensions_and_enums.sql` ✅
Postgres extensions and every enum type used platform-wide.

| Object | Purpose |
|---|---|
| `uuid-ossp`, `pgcrypto` | UUID generation |
| `vector` | pgvector — RAG embeddings |
| `pg_trgm` | Fuzzy transcript search |
| `user_role` | `admin` / `manager` / `agent` — drives all RLS |
| `framework_status` | `draft` / `published` / `archived` |
| `scoring_type` | `binary` / `scale_5` / `scale_10` / `numeric` |
| `call_status` | Pipeline lifecycle: pending → transcribing → … → evaluated |
| `speaker_role` | `agent` / `customer` / `system` / `unknown` |
| `evaluation_status`, `agent_run_status` | Pipeline state |
| `sentiment_label`, `risk_severity` | Derived-insight vocabulary |
| `job_type`, `job_status` | Background queue |
| `chat_role` | Chatbot messages |

Enums rather than free-text CHECKs, because Supabase generates them as
TypeScript union types — the frontend gets compile-time safety for free.

### `20260902000002_identity_and_teams.sql` ✅

| Table / function | What it does |
|---|---|
| `teams` | Billing / Technical / Retention. RLS scope boundary for managers. |
| `profiles` | One row per **login user**, 1:1 with `auth.users`. Holds `role` + `team_id`. |
| `support_agents` | The **person being evaluated**. Deliberately *not* tied to `auth.users`. |
| `set_updated_at()` | Shared trigger function, reused by every table with `updated_at`. |
| `handle_new_user()` | Auto-creates a `profiles` row on signup, defaulting to `agent`. |

> **The distinction that matters:** `profiles` = who logs in. `support_agents` =
> whose call is being scored. Keeping them separate is what lets you import a
> year of historical CSV data without creating fake login accounts for agents
> who have since left.

### `20260902000003_quality_framework.sql` ✅ ★ core of the project

| Table / function | What it does |
|---|---|
| `framework_versions` | The immutability unit. Partial unique index enforces **at most one** `published` version. |
| `sections` | Level 1. `weight`, `is_enabled`, `display_order`, stable `code`. |
| `subsections` | Level 2, under a section. |
| `criteria` | Level 3 — the leaves the LLM scores. Carries `guidance` (injected into the prompt), `examples`, `is_critical` (auto-fail), `allow_na`. |
| `guard_published_framework()` | Trigger on all three levels. **Refuses any write to a published or archived tree**, at the database level. |

> **How "no code changes" is delivered:** `criteria.guidance` is injected
> verbatim into the scoring agent's prompt. A business user rewriting that text
> in the admin panel changes how calls are scored, with no deploy.

> **Gotcha fixed during build:** `guard_published_framework()` originally used a
> `CASE` expression over `TG_TABLE_NAME`. plpgsql type-checks *every* branch
> against the actual record, so `new.section_id` failed when the trigger fired
> on `sections`. It is now an `IF/ELSIF` ladder, and handles `TG_OP='DELETE'`
> where `NEW` is unassigned.

### `20260902000004_calls_and_transcripts.sql` ✅

| Table | What it does |
|---|---|
| `ingestion_batches` | One row per CSV/JSON upload, with a per-row `error_log`. |
| `calls` | Call metadata. `team_id` is **snapshotted at ingest**, not derived, so attribution survives agent transfers. |
| `transcripts` | One per call. `full_text` + a generated `search_vector` tsvector for keyword search. |
| `transcript_turns` | Speaker turns with `char_start`/`char_end` **offsets into `full_text`**. |

> **Why transcripts are stored twice:** the explainability requirement says every
> score cites the exact justifying excerpt. Storing only a blob forces you to
> string-match the LLM's quote back into the text — and LLMs paraphrase, so that
> match fails constantly. Instead the agent cites a **turn index**, and the API
> resolves stored offsets into an exact character range. Verified: all 1,474
> seeded turns slice back byte-exact.

### `20260902000005_evaluations_and_scores.sql` ✅

| Table | What it does |
|---|---|
| `evaluations` | One pipeline run over one call. `is_current` (partial unique index) marks the one the dashboard shows; older runs are kept as history. |
| `criterion_scores` | Leaf scores. Snapshot columns make each row self-describing. |
| `score_citations` | ★ The explainability layer. Links a score to the turns that justified it, with `polarity` (supporting / detracting). |
| `subsection_scores`, `section_scores` | Materialised rollups — fast dashboards, and they preserve the weights used at the time. |

> **Why weights are snapshotted onto every score row:** a completed evaluation
> must stay fully explainable ("empathy was 20% of Communication back then")
> without joining to a framework version that may since have been archived.

### `20260902000006_agent_outputs.sql` ✅
Everything the non-scoring agents produce. All keyed on `evaluation_id`, not
`call_id` — an agent's output is a product of a *pipeline run*, so re-running
with a better model yields a second comparable set instead of overwriting.

| Table | Produced by |
|---|---|
| `call_summaries` | Summary agent — headline, narrative, `key_issues`, GIN-indexed `topics[]`, `next_actions` |
| `sentiment_analyses` | Sentiment agent — per-call rollup incl. **`sentiment_delta`** (closing − opening) |
| `sentiment_timeline` | Sentiment agent — per-turn scores driving the drill-down sparkline |
| `risk_flags` | Risk agent — plus a human triage layer (`is_acknowledged`, `is_false_positive`) |
| `call_statistics` | Preprocessing agent — deterministic, zero-LLM metrics like `agent_talk_ratio` |

### `20260902000007_pipeline_and_jobs.sql` ✅

| Object | What it does |
|---|---|
| `agent_runs` | One row **per agent, per evaluation**: prompt hash, model, raw + parsed output, tokens, latency, retries. |
| `jobs` | Postgres-backed work queue. No Redis, no Celery. |
| `claim_next_job()` | Atomic dequeue using `FOR UPDATE SKIP LOCKED` — safe with N concurrent workers. |
| `reclaim_stale_jobs()` | Requeues jobs orphaned by a crashed worker, with exponential backoff. |

> `agent_runs` is what makes the multi-agent claim demonstrable rather than
> rhetorical: open any call and show five discrete agent invocations with their
> own inputs and outputs.

### `20260902000008_rag_and_chat.sql` ✅

| Object | What it does |
|---|---|
| `transcript_chunks` | Vector index. Chunked **on turn boundaries** so passages stay coherent and citable. `vector(768)` + HNSW. |
| `chat_sessions`, `chat_messages` | Chatbot history. Messages store `citations`, `retrieved_chunks`, and the `generated_sql`. |
| `search_transcript_chunks()` | **Hybrid retrieval** — pgvector similarity fused with full-text rank via Reciprocal Rank Fusion (k=60). |

> **Why hybrid and not pure vector:** "which agents scored lowest on empathy
> this week?" cannot be answered by similarity search, because the answer exists
> in no single transcript. And embeddings blur exact tokens like `FIBER-300` or
> `error 651`, which is precisely what managers search for. RRF fuses by *rank*,
> sidestepping the fact that cosine distance and `ts_rank` are incomparable scales.

> **Why 768 dimensions:** `gemini-embedding-2` emits 3072 natively, but pgvector's
> HNSW index caps at 2000. 768 is a Matryoshka truncation — ~4× smaller index,
> retrieval quality within ~1%.

### `20260902000009_functions_and_views.sql` ✅ ★ the scoring engine

**Framework lifecycle**

| Function | What it does |
|---|---|
| `validate_framework_weights(version)` | Returns one row per problem: unbalanced level, or an enabled section with no enabled leaves. Empty result = publishable. |
| `normalize_framework_weights(version)` | The admin panel's "auto-balance" button. Rescales enabled siblings to sum to 100, preserving proportions. |
| `clone_framework_version(src)` | Deep-copies a tree into a new draft. Codes preserved, uuids fresh. The only sanctioned way to edit a published rubric. |
| `publish_framework_version(id)` | Validates → archives the incumbent → promotes the draft, atomically. Returns the archived id so the caller can diff. |

**Scoring**

| Function | What it does |
|---|---|
| `score_to_grade(pct)` | A/B/C/D/F banding. |
| `recompute_evaluation_scores(eval, [version])` | ★ Rolls criterion scores up to a final percentage in pure SQL. **Zero LLM calls.** Pass a different version to re-project onto new weights. Returns `missing_criteria`. |
| `reproject_evaluations_to_version(version)` | Bulk apply across history. Returns *recomputed* vs *needs-LLM* counts. |

> **The central insight of the whole project.** A framework change is one of two
> things, with wildly different costs:
> - **Re-weight / enable / disable** → pure arithmetic over scores that already
>   exist. Milliseconds. **Zero LLM calls.**
> - **Add / edit a criterion** → no score exists for that leaf, so the transcript
>   genuinely must be re-read. Queued as a background job.
>
> Collapsing these into "the framework changed, re-run everything" makes a weight
> tweak cost thousands of API calls. Separating them is the difference between a
> demo and a product.

> Scores are matched across versions by **code path**
> (`section_code`/`subsection_code`/`criterion_code`), never by uuid, because a
> cloned version has all-new uuids for semantically identical nodes.

> **Renormalisation:** every level divides by the sum of weights that *actually
> contributed*, not by 100. Disable three criteria and the rest scale up to fill
> the gap — instead of the section silently capping at 40%.

**Views**

| View | Backs |
|---|---|
| `v_call_overview` | Main call list; also the chatbot's analytical path |
| `v_agent_scorecard` | Agent leaderboard (incl. `score_stddev` — consistency is its own signal) |
| `v_section_performance` | Trend chart, sliced by team / agent / week |
| `v_criterion_performance` | Leaf-level `fail_rate_pct` — what a manager actually coaches on |
| `v_daily_score_trend` | Overview headline time series |

Plain views, not materialised: at this data volume Postgres answers in
milliseconds, and a plain view can never serve stale numbers — which matters
when a re-weight must show on the dashboard immediately.

### `20260902000010_rls_policies.sql` ✅

| Function | What it does |
|---|---|
| `auth_role()`, `auth_team_id()`, `is_admin()` | `SECURITY DEFINER` helpers. Must be — a policy on `profiles` that reads `profiles` would recurse infinitely. |
| `can_access_call(call_id)` | Single definition of call visibility, reused by 10+ policies so the three roles cannot drift apart. |

Access model: **admin** → everything · **manager** → their team · **agent** →
only calls they handled. Chat sessions are private to their owner with *no admin
override*, deliberately.

> The FastAPI backend uses the `service_role` key and bypasses RLS. These
> policies protect the path where the React client talks to Supabase directly —
> defence in depth, so a leaked anon key cannot read another team's calls.

---

## `supabase/seed.sql` ✅
Teams, 9 support agents, and **framework v1** — 5 sections, 12 sub-sections,
31 criteria, modelled on a real contact-centre scorecard.

Inserts the tree while the version is still `draft` (the immutability trigger
blocks writes to a published one), then calls `publish_framework_version()`,
which refuses to run unless every level sums to 100. Idempotent.

Two auto-fail criteria: `RECORDING_DISCLOSURE` and `IDENTITY_VERIFICATION`.
Three N/A-able criteria: `HOLD_ETIQUETTE`, `CORRECT_ESCALATION`,
`ACCURATE_PRICING_INFO`.

## `supabase/seeds/02_calls.sql` ✅ *(generated — do not edit)*
84 calls, 84 transcripts, 1,474 turns across 6 weeks. Regenerate with the script
below.

## `scripts/generate_seed_calls.py` ✅

| Function | What it does |
|---|---|
| `pick_tier(rng, skill)` | Draws a block quality tier from an agent's skill. Weighted, not deterministic — strong agents still have bad moments. |
| `build_transcript(...)` | Assembles greeting → issue → empathy → verification → diagnosis → [hold] → resolution → confirm → closing. Returns turns **and the tier map**. |
| `main()` | Emits idempotent SQL with exact char offsets computed in one pass. |

Three reasons this is a generator rather than 84 hand-written files:

1. **Ground truth.** Each block's intended quality tier is written to
   `calls.metadata.ground_truth`. Once the scoring agent runs, you can measure
   its agreement with the tier that actually produced the text — turning "the AI
   scores calls" into "the AI agrees with ground truth 87% of the time", a real
   evaluation section for the report.
2. **Agent personality.** Each agent has a fixed skill profile, so their calls
   are consistently strong or weak. Without it the leaderboard is pure noise.
3. **Compliance realism.** Weak agents skip the recording disclosure at a
   realistic rate, so the seed data naturally contains auto-fail calls.

Deterministic (`seed=42`), stdlib only, **no model downloads**.

## `supabase/tests/scoring_engine_test.sql` ✅
Runs in a transaction and rolls back. All four pass:

| Test | Asserts | Result |
|---|---|---|
| T1 | Uniform 80% across all 31 criteria rolls up to exactly 80.000, grade B | ✅ |
| T2 | An N/A criterion is **removed from the denominator**, not scored zero (`OPEN_SETUP` = 1.0, not 0.55) | ✅ |
| T3 | A failed critical criterion forces the call to 0 with `auto_fail_triggered` | ✅ |
| T4 | Re-weighting `RESOLUTION` 30%→70% moves the score 65%→85% **with zero LLM calls** | ✅ |

---

## Planned

| Path | Phase | Contents |
|---|---|---|
| `backend/app/` | 2 | FastAPI: framework CRUD, ingestion, evaluation trigger, chat |
| `backend/app/agents/` | 3 | `preprocessing.py`, `scoring.py`, `sentiment.py`, `risk.py`, `summary.py` |
| `backend/app/llm/` | 3 | Provider-agnostic adapter + retry/fallback ladder + `MOCK_LLM` mode |
| `backend/app/pipeline/` | 3-4 | LangGraph orchestration + aggregator |
| `backend/worker.py` | 3 | Job queue consumer |
| `frontend/src/lib/api.ts` | 5 | Typed API contract — the Lovable seam |
| `frontend/src/pages/` | 5-6 | Dashboard, call drill-down, framework admin, chat |
| `docs/ARCHITECTURE.md` | 8 | Report-ready write-up + diagrams |
