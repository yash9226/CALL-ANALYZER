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
├── backend/               ✅ FastAPI app (Phase 2) + pipeline (Phase 3-4, 7)
├── frontend/              🚧 Typed API contract ready (Phase 5); UI via Lovable
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

## `backend/` — FastAPI application ✅ *(Phase 2)*

```
backend/
├── pyproject.toml          Dependencies, ruff and pytest config
├── app/
│   ├── main.py             App entrypoint, CORS, exception handlers, lifespan
│   ├── config.py           All settings, loaded once from the repo-root .env
│   ├── db.py               asyncpg pool + query helpers
│   ├── errors.py           Domain exceptions -> HTTP responses
│   ├── security.py         JWT verification, roles, dev bypass
│   ├── schemas/            Pydantic models = the API contract
│   ├── routers/            HTTP layer
│   └── services/           Business logic
└── tests/                  54 tests, all passing
```

### `app/config.py` ✅
`Settings` (pydantic-settings), cached by `get_settings()`. Every tunable lives
here rather than being read from `os.environ` at the point of use, so the whole
configuration surface is in one file and typos fail at startup.

Notable properties: `cors_origin_list`, `fallback_model_list`,
`is_local_database` (used by the dev-bypass safety check).

### `app/db.py` ✅
| Function | Purpose |
|---|---|
| `connect()` / `disconnect()` | Pool lifecycle, driven by the app lifespan |
| `_init_connection()` | Registers a **jsonb codec** so jsonb columns decode to dicts |
| `fetch` / `fetchrow` / `fetchval` / `execute` | Thin wrappers that keep `dict(row)` out of every service |

> **Raw SQL, no ORM.** The scoring engine lives in Postgres functions
> (`recompute_evaluation_scores`, `publish_framework_version`, `claim_next_job`).
> An ORM would be a layer these calls punch straight through anyway.

> **Gotcha fixed during build:** with a jsonb codec registered, you pass the
> Python object, *not* `json.dumps(obj)`. Encoding at the call site as well
> stores a JSON string containing JSON. Three tests caught this.

### `app/errors.py` ✅
`AppError` / `NotFound` / `Conflict` / `ValidationError` / `Forbidden`, plus
`postgres_error_handler`, which maps SQLSTATEs onto meaningful HTTP codes.

> The database raises *deliberate*, human-readable errors — the immutability
> trigger and `publish_framework_version()` both raise `check_violation` with a
> sentence written for a user. Those surface as **409 with the original text**,
> so the admin UI can show exactly what is wrong instead of "publish failed".

### `app/security.py` ✅
| Object | Purpose |
|---|---|
| `CurrentUser` | Frozen dataclass: id, email, role, team_id |
| `get_current_user()` | Verifies the Supabase HS256 JWT, loads the `profiles` row |
| `require_admin()` | Gate on every framework-mutating endpoint |
| `DEV_USER` | Identity used when `AUTH_DEV_BYPASS=true` |

> The backend connects as the database owner and **bypasses RLS** — the pipeline
> must write scores for every team. So authorisation here is not decorative:
> `require_admin` and `call_service._scope_clause` are the real access control
> for API traffic. RLS guards the separate browser-to-Supabase path.

### `app/services/transcript_parser.py` ✅ ★ protects the citation invariant
| Function | Purpose |
|---|---|
| `normalise_speaker()` | Maps `AGENT_01`, `Rep`, `CSR`, `CALLER`… onto the `speaker_role` enum |
| `parse_text_transcript()` | Speaker-prefixed text, multi-line turns, `[00:01:23]` timestamps |
| `parse_turn_list()` | JSON turn arrays; tolerates `role`/`content`/`utterance` aliases |
| `_assemble()` | **The only place `full_text` is built**, with offsets computed in the same pass |
| `ParsedTranscript.verify()` | Slices every offset back and compares — called unconditionally |
| `compute_statistics()` | Deterministic, zero-LLM metrics (talk ratio, interruption proxy) |

> **Why this file exists.** `full_text` is canonical and every turn offset indexes
> into it. The parser therefore never accepts a caller-supplied `full_text`
> alongside separate turns — it rebuilds both from one source, making
> disagreement structurally impossible rather than merely unlikely.

> Handles the trap case: `"The problem is simple: my bill doubled"` must not be
> read as a speaker named *"The problem is simple"*. Tested.

### `app/services/framework_service.py` ✅
Version queries, tree assembly, CRUD for all three levels, and lifecycle
(`clone`, `publish`, `validate`, `normalize`, `reproject`, `ensure_draft`).

> **No auto-cloning.** Silently forking the rubric because someone nudged a
> weight would make version history unpredictable and litter the list with
> accidental drafts. Mutating a published version returns **409 with an
> actionable message**; `ensure_draft()` (`POST /api/framework/draft`) returns the
> existing draft or clones one, so the UI can say "Editing draft v3" *before* the
> first keystroke.

### `app/services/ingestion_service.py` ✅
| Function | Purpose |
|---|---|
| `normalise_row()` | Maps `call_id`/`conversation_id`/`body`/`length`… onto canonical fields; unknown columns are **preserved into metadata** |
| `ingest_one()` | Call + transcript + turns in **one transaction** |
| `parse_upload()` | CSV or JSON, incl. `{"calls": [...]}` wrappers |
| `ingest_batch()` | **Partial-tolerant** bulk import |

> Three bad rows in a 500-row CSV import 497 calls and log three errors with row
> numbers — rather than failing the whole upload. Re-posting the same
> `call_code` **updates in place**, so an interrupted import is safe to re-run.

### `app/services/call_service.py` ✅
`list_calls()` (14 filters, full-text search, sorting, pagination),
`get_call_detail()`, `get_transcript()`.

> `_scope_clause()` is the access control: admin sees all, manager sees their
> team, agent sees their own calls. It **fails closed** — a manager with no team
> sees nothing. `_assert_visible()` returns **404 rather than 403**, because
> confirming a call exists is itself a small leak.

> The drill-down is deliberately one response, not eight endpoints: the page
> always renders all of it together, and a single payload keeps the frontend
> free of loading-state choreography. Citations are aggregated inline with
> `jsonb_agg` to avoid N+1 across ~31 scores.

### `app/routers/` ✅ — 29 operations across 26 paths

| File | Endpoints |
|---|---|
| `framework.py` | 19 — versions, active, draft, clone, validate, normalize, publish, apply, CRUD ×3 levels, reorder |
| `calls.py` | 3 — list with filters, drill-down, transcript |
| `ingestion.py` | 4 — single call, batch upload, batch list, batch detail |
| `meta.py` | 3 — health, teams, agents |

Key endpoints:

| Endpoint | What it does |
|---|---|
| `POST /api/framework/draft` | Returns an editable draft, cloning the published version if needed |
| `GET  /api/framework/versions/{id}/validate` | Live weight/structure problems; the admin UI polls it while editing |
| `POST /api/framework/versions/{id}/normalize` | Auto-balance to 100 at every level |
| `POST /api/framework/versions/{id}/publish` | Validate → archive incumbent → promote, atomically |
| `POST /api/framework/versions/{id}/apply` | Re-project across history; returns *recomputed instantly* vs *queued for re-scoring* |

## `backend/tests/` ✅ — 54 tests, all passing

| File | Tests | Covers |
|---|---|---|
| `test_transcript_parser.py` | 30 | Speaker normalisation, multi-line turns, timestamps, the colon-in-a-sentence trap, offset integrity |
| `test_api_integration.py` | 24 | Immutability, the full draft→publish cycle, filters, search, pagination, ingestion, partial-tolerant batches |
| `conftest.py` | — | Fixtures that restore the seeded state so the suite is re-runnable |

Notable assertions:
- Editing, deleting or adding to a **published** version all return 409.
- Publishing an **unbalanced** tree returns 409 with the specific imbalance.
- A CSV with 3 good rows and 1 broken one yields **3 calls and 1 logged error**.
- Re-ingesting a `call_code` **replaces** its turns rather than merging them.
- Turn offsets slice back byte-exact **through the API**, not just in the DB.

---

## `backend/app/llm/` — provider abstraction ✅ *(Phase 3)*

Every agent talks to this, never to Gemini directly.

### `base.py`
`LLMResult` (text, parsed, model, tokens, latency, attempts, fallback_chain),
`LLMProvider` protocol, `LLMError`, and `PRICING` / `estimate_cost()`.

### `gemini.py` — `GeminiProvider`
| Method | Purpose |
|---|---|
| `_post()` | **The reliability core.** Two nested loops: a model ladder, and exponential backoff within each model |
| `generate_json()` | Constrained decoding via Gemini's native `responseSchema` |
| `embed()` | 768-d embeddings (truncated from the native 3072) |
| `transcribe()` | Audio → diarised transcript, via the API |

> **Why the retry machinery is not defensive over-engineering.** Google's free
> tier returned `503 "experiencing high demand"` repeatedly during this build,
> and sometimes simply hung. A live run observed here needed **3 attempts across
> a 503 and a ReadTimeout** before succeeding. Without the ladder, one spike
> would fail an entire 84-call run.

> Retryable: 429, 500, 502, 503, 504, timeouts. **Not** retryable: 400 and 403 —
> a malformed request or bad key fails identically forever, so retrying only
> burns quota.

> **Bug caught by a test:** on fallback the provider reported the model that
> *failed* rather than the one that succeeded, so `agent_runs.model` would have
> been wrong exactly when it mattered most. `_post()` now returns the successful
> candidate explicitly.

### `mock.py` — `MockProvider` ⚠️ **not a local model**
No weights, no downloads, nothing on the CPU or GPU. A keyword rule engine
returning schema-conformant fixtures.

| Object | Purpose |
|---|---|
| `Rule` | `positive` / `negative` phrases, `na_unless`, `scope`, `needed_for_full` |
| `RULES` | One rule per criterion code, all 31 |
| `evaluate_rule()` | Scores a criterion and produces real citations into real turns |
| `_score` / `_summary` / `_sentiment` / `_risk` | Per-agent handlers |
| `embed()` | Deterministic hash-based vectors — stable, but carrying no meaning |

Three reasons it exists:
1. **A demo cannot depend on a free-tier API being healthy.**
2. Tests need to be fast, free and deterministic.
3. **It is a rule-based BASELINE.** Same transcripts, same rubric — so the report
   can compare keyword rules against the LLM on ground-truth labels, which is a
   far stronger evaluation than reporting LLM numbers alone.

> `scope` restricts each rule to the relevant part of the call, so a "thank you"
> in the closing cannot rescue a greeting criterion. Tested.

---

## `backend/app/agents/` — the five agents ✅

### `base.py`
| Object | Purpose |
|---|---|
| `PipelineContext` | State threaded through the pipeline; `transcript_for_prompt()` renders turns with `[n]` markers |
| `Agent.run()` | Wraps `execute()` in an `agent_runs` row: prompt hash, model, I/O, tokens, latency, retries |
| `call_llm()` | Invokes the provider and returns `(parsed, telemetry)` |

> **Failure policy.** An agent declares whether it is `critical`. Failed scoring
> fails the evaluation — a call with no scores is not an evaluation. Failed
> sentiment/risk/summary is recorded and the pipeline continues: a missing
> summary is a degraded result, not a reason to discard 31 good scores.

> On a long call `transcript_for_prompt()` keeps **both ends**. Truncating the
> tail would systematically penalise the CLOSING section.

| Agent | Step | LLM | Critical | Writes |
|---|---|---|---|---|
| `PreprocessingAgent` | 1 | ✗ | ✓ | `call_statistics` |
| `ScoringAgent` | 2 | ✓ | ✓ | `criterion_scores`, `score_citations` |
| `SentimentAgent` | 3 | ✓ | ✗ | `sentiment_analyses`, `sentiment_timeline` |
| `RiskAgent` | 4 | ✓ | ✗ | `risk_flags` |
| `SummaryAgent` | 5 | ✓ | ✗ | `call_summaries` |

### `scoring.py` — the core
> **One request per SUB-SECTION, not per criterion.** 31 criteria would mean 31
> calls: slow, expensive, and *worse quality*, because the model would judge
> "acknowledges emotion" without seeing "uses empathy statements" even though the
> same passage informs both. Sub-sections give 12 calls and a shared judgement
> context — and they are the grouping the rubric author already chose.

> **Citations by turn index, never by quoted text.** The model cites `[n]`; we
> resolve stored offsets. Asking for quoted text would require string-matching
> the model's output back into the transcript, and models paraphrase — so that
> match fails constantly.

> **The framework IS the prompt.** Each criterion's `guidance` is injected
> verbatim. That is the whole "configurable without code changes" mechanism.

> Guards: a hallucinated `criterion_code` is discarded rather than creating a
> phantom score; a citation to a turn that does not exist is dropped; scores are
> clamped to range; one failed sub-section does not discard the other eleven.

### `sentiment.py`
> **Trajectory, not average.** A call opening at −0.8 and closing at +0.4 is a
> SUCCESS. Its average is still negative, so an average would rank it with a
> mildly unhappy call and hide the best coaching signal in the dataset.
> `sentiment_delta` is the headline metric, and it is computed in Python —
> arithmetic should not be delegated to a language model.

### `risk.py`
> Separate from scoring because it has a different consumer (a triage queue
> today, not coaching over weeks) and a different failure mode: a missed flag is
> worse than a wrong score. Re-running replaces only flags a human has **not**
> triaged — discarding a reviewer's decision would be worse than a duplicate.

---

## `backend/app/pipeline/` ✅

### `graph.py` — LangGraph orchestration
```
START → preprocessing → ┬→ scoring   ─┐
                        ├→ sentiment ─┤
                        ├→ risk      ─┼→ aggregation → END
                        └→ summary   ─┘
```
Those four agents are genuinely independent, so an evaluation takes as long as
its slowest agent rather than the sum of all four.

`PipelineState` uses `operator.add` reducers on `completed`/`failed` — without
them LangGraph raises a concurrent-update error when the four branches write at
once.

> **Why LangGraph rather than `asyncio.gather`.** The concurrency itself is four
> lines. What the graph buys is that the pipeline's STRUCTURE is data: it renders
> as a diagram (`render_mermaid()`, exposed at
> `GET /api/evaluations/pipeline/graph`), so the architecture diagram in the
> report is generated from the code that actually runs and cannot drift.

### `aggregator.py`
Contains almost no logic, deliberately. All weighting, N/A renormalisation and
auto-fail handling lives in `recompute_evaluation_scores()` — the same function
used when an admin re-weights the rubric, so a fresh evaluation and a re-weighted
historical one can never disagree.

---

## `backend/app/services/evaluation_service.py` ✅
> **Promotion is deferred until success.** A new evaluation is inserted with
> `is_current = false` and promoted only when it completes. A failed re-run
> therefore cannot destroy a good previous result — the dashboard keeps showing
> the last evaluation that worked, and the failure stays in history for diagnosis.

## `backend/app/worker.py` ✅
Consumes `jobs` via `claim_next_job()` (FOR UPDATE SKIP LOCKED). Handles
SIGINT/SIGTERM by finishing the current job. Calls `reclaim_stale_jobs()` on
startup and periodically, so a crashed worker's jobs are requeued with backoff
rather than stranded.

---

## Phase 3 verification

Full run over the seeded corpus, MOCK provider:

| Metric | Result |
|---|---|
| Calls evaluated | 84 / 84, **0 failures** |
| Criterion scores | 2,604 |
| Citations | 2,780 — **all 2,780 slice back byte-exact** |
| N/A scores | 140 (exercising renormalisation) |
| Auto-fails | 11, each with a stated reason |
| Agent runs recorded | 420, **0 failed** |

Ground-truth agreement (seed data records the quality tier each block was
generated from):

| Check | Result |
|---|---|
| Pearson r, seeded agent skill vs AI score (n=84) | **0.64** |
| `GREETING_BRANDED` by seeded tier | good 100% · mid 100% · poor 0% |
| `ACKNOWLEDGE_EMOTION` by seeded tier | good 100% · mid 8.7% · poor 0% |

### Live Gemini validation

One call was also evaluated with the real provider, end to end:

| | Rule baseline (mock) | Gemini 3.6/3.1-flash |
|---|---|---|
| Score | 64.5% (grade D) | **0% (grade F, auto-fail)** |
| `IDENTITY_VERIFICATION` | 1 (met) | **0 (not met)** |
| `PLAIN_LANGUAGE` | 0 | 5 |
| `ROOT_CAUSE_ID` | 0 | 5 |
| Wall time / cost | 94 ms / $0 | 195 s / **$0.0043** |

Gemini's reasoning on the criterion that flipped the result:

> *"The agent only requested the account number and did not perform a two-factor
> verification process before discussing the account status and area outage."*

The rubric guidance requires **at least two identifiers**. The agent asked for
one. The keyword rule saw "account number" and passed it; the LLM read the
guidance and correctly auto-failed the call.

This is the clearest justification in the project for using an LLM rather than
keyword rules, and it is measured rather than asserted. It also shows the two
scorers disagreeing in *both* directions: the rules under-scored
`PLAIN_LANGUAGE` and `ROOT_CAUSE_ID`, which need semantic judgement they cannot
perform.

**The fallback ladder engaged for real.** `model_used` on that evaluation reads
`gemini-3.1-flash-lite, gemini-3.6-flash`: the primary model hit HTTP 429 quota
exhaustion mid-run and the remaining sub-sections were scored by the fallback.
The evaluation still completed with all 31 criteria scored and no errors.

> **An honest finding to carry into the report.** The rule baseline separates
> *poor* from *not-poor* perfectly, but cannot tell *good* from *mid* on
> `GREETING_BRANDED` — keyword matching detects presence, not quality. That is a
> concrete, testable hypothesis for the LLM to beat, and a better evaluation
> story than a single unexplained accuracy figure.

## `backend/tests/` — 93 tests, all passing

| File | Tests | Covers |
|---|---|---|
| `test_transcript_parser.py` | 30 | Parsing, offsets, speaker normalisation |
| `test_api_integration.py` | 24 | Framework CRUD, immutability, ingestion |
| `test_pipeline.py` | 23 | Rule engine, graph shape, end-to-end run, citations, auto-fail, rerun history |
| `test_llm_provider.py` | 16 | Retry on 503/timeout, no-retry on 400/403, fallback ladder, truncated JSON, constrained decoding |

---

## `backend/app/services/analytics_service.py` ✅ *(Phase 5)*

| Function | Backs |
|---|---|
| `overview()` | Six KPI cards, each with period-over-period change |
| `trend()` | The headline time-series chart (day/week/month) |
| `section_performance()` | "Where are we weak" bar chart, weakest first |
| `criterion_performance()` | The coaching list, with fail rates |
| `agent_leaderboard()` | Agent table, including `score_stddev` |
| `score_distribution()` | Histogram in 10-point bands + grade tally |
| `flag_summary()` | Risk counts by type/severity + recent open flags |
| `topic_breakdown()` | Volume and score by topic tag |

> **Aggregation happens in Postgres, not the browser.** Shipping thousands of
> rows to the client to reduce in JavaScript would be slow, would leak data the
> caller may not be allowed to see, and would put the definition of a metric in
> the client.

> **Scoping is derived from the caller's profile, never trusted from the
> request.** A manager hitting `/overview` gets their team's overview without
> passing `team_id`. `_scope()` **fails closed**: a manager with no team sees
> zero calls, not all of them. Tested explicitly.

> **Metric definitions that charts silently depend on:** `fail_rate_pct` counts
> only *applicable* scores in both numerator and denominator, so a criterion that
> rarely applies is not misreported as widely failed. `score_distribution()`
> emits all ten bands including empty ones, so the x-axis is stable rather than
> collapsing gaps and misleading the reader.

> `change_pct` compares against the immediately preceding window of **equal
> length**, and returns `null` — not 0 — when there is no comparable prior data.

## `backend/app/routers/analytics.py` ✅
Eight endpoints, all taking the same filter set (`date_from`, `date_to`,
`team_id`, `support_agent_id`).

## `frontend/src/lib/api.ts` ✅ — **the seam**
880 lines: every TypeScript type mirroring the live schema, an `api.*` function
per endpoint, `ApiError` with an `isConflict` helper, and display helpers
(`formatScore`, `gradeFor`, `formatDuration`, `highlightSegments`).

Type-checks clean under `strict: true`.

> **Why a hand-written contract instead of letting Lovable improvise.** Left
> alone, Lovable creates its own Supabase tables and queries; merging that into a
> real schema is miserable. Pinning every network call to one typed module makes
> integration a swap (`MOCK = false` + a base URL) rather than a rewrite.

> Display helpers live here so formatting cannot drift between pages — in
> particular `formatScore()`, which renders an inapplicable criterion as "N/A"
> rather than 0. Rendering it as 0 would misrepresent the agent, since the
> backend excludes it from the weighted denominator entirely.

> `highlightSegments()` slices `full_text` using stored `char_start`/`char_end`
> offsets. The frontend must never text-search for a citation's `quoted_text` —
> models paraphrase, so that search fails.

## `docs/LOVABLE_PROMPT.md` ✅
The paste-ready prompt: non-negotiable rules, design system, semantic colour
table, page-by-page specification for the dashboard / calls list / drill-down,
behaviour requirements, realistic mock values drawn from the actual seeded
corpus, and a verification checklist.

## `backend/tests/test_api_contract.py` ✅ — guards the seam
18 tests freezing the field names the frontend depends on.

> The frontend is generated externally against hand-written types, so nothing
> otherwise stops the backend drifting away from them — a renamed field compiles
> fine on both sides and simply renders as `undefined`. These tests turn that
> into a build failure. Extra fields are allowed (additive changes are
> backwards-compatible); removals and renames are not.

Also asserts the **error envelope** (`error.code` / `.message` / `.details`),
because `ApiError` destructures it and a bare string body would break every
error path in the UI.

## Phase 5 verification

| Check | Result |
|---|---|
| Backend test suite | **133 passing** (30 parser · 24 API · 23 pipeline · 16 LLM · 22 analytics · 18 contract) |
| API surface | 42 operations across 39 paths |
| `api.ts` under `tsc --strict` | clean |
| Evaluation coverage | 84 / 84 calls |

> **A bug this phase surfaced in my own tests.** Dashboard coverage read 82/84.
> Cause: test cleanup deleted a *promoted* evaluation, leaving those calls with
> no current evaluation and silently degrading the seeded dataset.
> `conftest.drop_evaluation()` now restores the superseded evaluation on
> teardown. The dashboard is what made it visible — aggregate views expose data
> integrity problems that per-record tests walk straight past.

---

## Planned

| Path | Phase | Contents |
|---|---|---|
| `frontend/src/pages/` | 5-6 | Dashboard, call drill-down, framework admin, chat |
| `docs/ARCHITECTURE.md` | 8 | Report-ready write-up + diagrams |
